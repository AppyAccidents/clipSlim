import Foundation
import CoreServices

@Observable
final class FolderWatcher {
    
    private(set) var isWatching = false
    private(set) var watchedPath: String = ""
    
    private var stream: FSEventStreamRef?
    private var debounceTimer: Timer?
    private var pendingPaths: Set<String> = []
    private var processedFiles: [String] = [] // Array for LRU eviction
    private var processedFilesSet: Set<String> = [] // Set for O(1) lookup
    private var preExistingFiles: Set<String> = []
    
    private let maxProcessedFiles = 1000
    private let maxPreExistingFiles = 5000
    
    private let debounceInterval: TimeInterval = 0.3
    private let supportedExtensions: Set<String> = ["jpg", "jpeg", "png", "tiff", "tif", "bmp", "heic"]
    private let optimizedSuffix = "-optimized"
    private let log = Logger.shared
    
    var onFileDetected: ((URL) -> Void)?
    
    func start(path: String) {
        guard !isWatching, !path.isEmpty else { return }
        
        let expandedPath = NSString(string: path).expandingTildeInPath
        
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: expandedPath, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            log.folder("Invalid directory path: \(expandedPath)", type: .error)
            return
        }
        
        watchedPath = expandedPath
        catalogExistingFiles()
        
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        
        let pathsToWatch = [expandedPath] as CFArray
        
        stream = FSEventStreamCreate(
            nil,
            folderWatcherCallback,
            &context,
            pathsToWatch,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            debounceInterval,
            UInt32(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes)
        )
        
        guard let stream = stream else {
            log.folder("Failed to create FSEvent stream", type: .error)
            return
        }
        
        FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        FSEventStreamStart(stream)
        isWatching = true
        log.folder("Folder watcher started: \(expandedPath)")
    }
    
    func stop() {
        if let stream = stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            self.stream = nil
        }
        debounceTimer?.invalidate()
        debounceTimer = nil
        pendingPaths.removeAll()
        processedFiles.removeAll()
        processedFilesSet.removeAll()
        preExistingFiles.removeAll()
        isWatching = false
        watchedPath = ""
        log.folder("Folder watcher stopped")
    }
    
    func enqueueForDebounce(path: String) {
        pendingPaths.insert(path)
        
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: debounceInterval, repeats: false) { [weak self] _ in
            self?.processPendingPaths()
        }
    }
    
    // MARK: - Private
    
    private func catalogExistingFiles() {
        preExistingFiles.removeAll()
        guard let enumerator = FileManager.default.enumerator(atPath: watchedPath) else { return }
        var count = 0
        while let file = enumerator.nextObject() as? String {
            guard count < maxPreExistingFiles else {
                log.folder("Pre-existing files limit reached (\(maxPreExistingFiles)), some files may be re-processed")
                break
            }
            preExistingFiles.insert((watchedPath as NSString).appendingPathComponent(file))
            count += 1
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
        
        // Filter: supported extension
        guard supportedExtensions.contains(ext) else { return }
        
        // Filter: skip files with optimized suffix
        let nameWithoutExt = url.deletingPathExtension().lastPathComponent
        guard !nameWithoutExt.hasSuffix(optimizedSuffix) else {
            log.folder("Skipping already-optimized file: \(url.lastPathComponent)")
            return
        }
        
        // Filter: skip pre-existing files
        guard !preExistingFiles.contains(path) else { return }
        
        // Filter: skip already-processed files
        guard !processedFilesSet.contains(path) else { return }
        
        // Verify file exists and is readable
        guard FileManager.default.isReadableFile(atPath: path) else { return }
        
        // Add to processed with LRU eviction
        if processedFiles.count >= maxProcessedFiles {
            if let oldest = processedFiles.first {
                processedFiles.removeFirst()
                processedFilesSet.remove(oldest)
            }
        }
        processedFiles.append(path)
        processedFilesSet.insert(path)
        log.folder("New image file detected: \(url.lastPathComponent)")
        onFileDetected?(url)
    }
}

// MARK: - FSEvents C Callback
private let folderWatcherCallback: FSEventStreamCallback = { _, info, numEvents, eventPaths, eventFlags, _ in
    guard let info = info else { return }
    let watcher = Unmanaged<FolderWatcher>.fromOpaque(info).takeUnretainedValue()
    
    guard let cfArray = unsafeBitCast(eventPaths, to: NSArray.self) as? [String] else { return }
    
    for i in 0..<numEvents {
        let flags = eventFlags[i]
        if flags & UInt32(kFSEventStreamEventFlagItemIsFile) != 0 {
            watcher.enqueueForDebounce(path: cfArray[i])
        }
    }
}
