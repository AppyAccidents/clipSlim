import Foundation
import CoreServices

struct BookmarkResolution {
    let url: URL
    let isStale: Bool
}

enum FolderBookmarkManager {
    static func makeWatchedFolder(from url: URL) throws -> WatchedFolder {
        let bookmarkData = try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
        return WatchedFolder(displayName: url.lastPathComponent, bookmarkData: bookmarkData)
    }

    static func resolve(_ watchedFolder: WatchedFolder) throws -> BookmarkResolution {
        var stale = false
        let url = try URL(
            resolvingBookmarkData: watchedFolder.bookmarkData,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &stale
        )
        return BookmarkResolution(url: url, isStale: stale)
    }
}

@Observable
final class FolderWatcher {

    private(set) var isWatching = false
    private(set) var watchedPaths: [String] = []

    private var stream: FSEventStreamRef?
    private var debounceTimer: Timer?
    private var pendingPaths: Set<String> = []
    private var processedFiles: [String] = []
    private var processedFilesSet: Set<String> = []
    private var preExistingFiles: Set<String> = []
    private var securityScopedURLs: [URL] = []

    private let maxProcessedFiles = 2000
    private let maxPreExistingFiles = 20000

    private let debounceInterval: TimeInterval = 0.3
    private static let supportedExtensions: Set<String> = ["jpg", "jpeg", "png", "tiff", "tif", "bmp", "heic"]
    // Chosen strategy to avoid self-processing loops: outputs go into "Optimized" subfolder.
    private let optimizedOutputSubfolder = "Optimized"
    private let log = Logger.shared

    var onFileDetected: ((URL) -> Void)?
    var onBookmarkNeedsRefresh: ((WatchedFolder) -> Void)?

#if DEBUG
    private(set) var debugStreamStartCount = 0
    private(set) var debugStreamStopCount = 0
    private(set) var debugDebounceTimerRecreationCount = 0
    private(set) var debugMaxPendingPathSetSize = 0
#endif

    func start(folders: [WatchedFolder]) {
        stop()
        guard !folders.isEmpty else { return }

        var resolvedPaths: [String] = []

        for folder in folders {
            do {
                let resolution = try FolderBookmarkManager.resolve(folder)
                if resolution.url.startAccessingSecurityScopedResource() {
                    securityScopedURLs.append(resolution.url)
                }

                if resolution.isStale {
                    onBookmarkNeedsRefresh?(folder)
                }

                var isDirectory: ObjCBool = false
                let path = resolution.url.path
                guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue else {
                    log.folder("Invalid directory path in bookmark: \(path)", type: .error)
                    continue
                }
                resolvedPaths.append(path)
            } catch {
                log.folder("Failed to resolve bookmark for \(folder.displayName): \(error.localizedDescription)", type: .error)
            }
        }

        guard !resolvedPaths.isEmpty else { return }

        watchedPaths = resolvedPaths
        catalogExistingFiles()

        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        stream = FSEventStreamCreate(
            nil,
            folderWatcherCallback,
            &context,
            resolvedPaths as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            debounceInterval,
            UInt32(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes)
        )

        guard let stream else {
            log.folder("Failed to create FSEvent stream", type: .error)
            return
        }

        FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        FSEventStreamStart(stream)
        isWatching = true
#if DEBUG
        debugStreamStartCount += 1
#endif
        log.folder("Folder watcher started for \(resolvedPaths.count) folder(s)")
    }

    func stop() {
        if let stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            self.stream = nil
#if DEBUG
            debugStreamStopCount += 1
#endif
        }

        securityScopedURLs.forEach { $0.stopAccessingSecurityScopedResource() }
        securityScopedURLs.removeAll()

        debounceTimer?.invalidate()
        debounceTimer = nil
        pendingPaths.removeAll()
        processedFiles.removeAll()
        processedFilesSet.removeAll()
        preExistingFiles.removeAll()
        watchedPaths.removeAll()
        isWatching = false
        log.folder("Folder watcher stopped")
    }

    func shutdown() {
        stop()
        onFileDetected = nil
        onBookmarkNeedsRefresh = nil
    }

    func enqueueForDebounce(path: String) {
        pendingPaths.insert(path)
#if DEBUG
        debugMaxPendingPathSetSize = max(debugMaxPendingPathSetSize, pendingPaths.count)
#endif

        debounceTimer?.invalidate()
#if DEBUG
        debugDebounceTimerRecreationCount += 1
#endif
        debounceTimer = Timer.scheduledTimer(withTimeInterval: debounceInterval, repeats: false) { [weak self] _ in
            self?.processPendingPaths()
        }
    }

    func outputURL(for inputURL: URL, format: ImageFormat) -> URL {
        let parent = inputURL.deletingLastPathComponent()
        let optimizedDir = parent.appendingPathComponent(optimizedOutputSubfolder, isDirectory: true)
        let nameWithoutExt = inputURL.deletingPathExtension().lastPathComponent
        return optimizedDir.appendingPathComponent("\(nameWithoutExt)-optimized.\(format.fileExtension)")
    }

    static func isSupportedImageFileExtension(_ ext: String) -> Bool {
        supportedExtensions.contains(ext.lowercased())
    }

    // MARK: - Private

    private func catalogExistingFiles() {
        preExistingFiles.removeAll()

        var count = 0
        for path in watchedPaths {
            guard let enumerator = FileManager.default.enumerator(atPath: path) else { continue }
            while let file = enumerator.nextObject() as? String {
                guard count < maxPreExistingFiles else {
                    log.folder("Pre-existing files limit reached (\(maxPreExistingFiles)), some files may be re-processed")
                    return
                }
                preExistingFiles.insert((path as NSString).appendingPathComponent(file))
                count += 1
            }
        }

        log.folder("Cataloged \(preExistingFiles.count) pre-existing files")
    }

    private func processPendingPaths() {
        let paths = pendingPaths
        pendingPaths.removeAll()

        for path in paths {
            processFile(at: path)
        }
    }

    private func processFile(at path: String) {
        let url = URL(fileURLWithPath: path)
        let ext = url.pathExtension.lowercased()

        guard Self.isSupportedImageFileExtension(ext) else { return }

        if path.contains("/\(optimizedOutputSubfolder)/") {
            return
        }

        guard !preExistingFiles.contains(path) else { return }
        guard !processedFilesSet.contains(path) else { return }
        guard FileManager.default.isReadableFile(atPath: path) else { return }

        if processedFiles.count >= maxProcessedFiles, let oldest = processedFiles.first {
            processedFiles.removeFirst()
            processedFilesSet.remove(oldest)
        }

        processedFiles.append(path)
        processedFilesSet.insert(path)
        log.folder("New image file detected: \(url.lastPathComponent)")
        onFileDetected?(url)
    }
}

private let folderWatcherCallback: FSEventStreamCallback = { _, info, numEvents, eventPaths, eventFlags, _ in
    guard let info else { return }
    let watcher = Unmanaged<FolderWatcher>.fromOpaque(info).takeUnretainedValue()

    let pathsArray = Unmanaged<CFArray>.fromOpaque(eventPaths).takeUnretainedValue() as NSArray
    guard let stringPaths = pathsArray as? [String] else { return }

    let eventCount = Int(numEvents)
    guard stringPaths.count >= eventCount else { return }

    for i in 0..<eventCount {
        let flags = eventFlags[i]
        if flags & UInt32(kFSEventStreamEventFlagItemIsFile) != 0 {
            watcher.enqueueForDebounce(path: stringPaths[i])
        }
    }
}
