import Foundation
import AppKit
import CryptoKit
import UniformTypeIdentifiers

@Observable
final class ClipboardWatcher {

    private(set) var isWatching = false
    private(set) var currentPollInterval: TimeInterval = PollingProfile.active.rawValue

    private var timer: Timer?
    private var lastSeenChangeCount: Int = 0
    private var isWritingToPasteboard = false
    private var lastWrittenHash: String = ""
    private var lastChangeDate = Date()

    private let log = Logger.shared

    var onImageDetected: ((Data) -> Void)?

    enum PollingProfile: TimeInterval {
        case active = 0.5
        case warmIdle = 1.5
        case idle = 3.0
    }

    func start() {
        guard !isWatching else { return }
        isWatching = true
        lastSeenChangeCount = NSPasteboard.general.changeCount
        lastChangeDate = Date()
        scheduleTimer(interval: PollingProfile.active.rawValue)
        log.clipboard("Clipboard watcher started (changeCount: \(lastSeenChangeCount))")
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isWatching = false
        currentPollInterval = PollingProfile.active.rawValue
        log.clipboard("Clipboard watcher stopped")
    }

    func writeToPasteboard(data: Data, format: ImageFormat) {
        isWritingToPasteboard = true
        let pb = NSPasteboard.general
        pb.clearContents()

        let pasteboardType: NSPasteboard.PasteboardType = {
            switch format {
            case .png:
                return .png
            case .jpeg:
                return NSPasteboard.PasteboardType(UTType.jpeg.identifier)
            }
        }()
        pb.setData(data, forType: pasteboardType)

        lastSeenChangeCount = pb.changeCount
        lastWrittenHash = sha256(data)
        lastChangeDate = Date()
        isWritingToPasteboard = false

        log.clipboard("Wrote optimized \(format.rawValue) to pasteboard (changeCount: \(lastSeenChangeCount))")
    }

    func removeImageContentSafely() -> Bool {
        let pb = NSPasteboard.general
        guard let items = pb.pasteboardItems, !items.isEmpty else { return false }

        var rebuilt: [NSPasteboardItem] = []
        var sawImageType = false

        for item in items {
            let newItem = NSPasteboardItem()
            for type in item.types {
                if isImagePasteboardType(type) {
                    sawImageType = true
                    continue
                }
                if let data = item.data(forType: type) {
                    newItem.setData(data, forType: type)
                } else if let text = item.string(forType: type) {
                    newItem.setString(text, forType: type)
                }
            }
            if !newItem.types.isEmpty {
                rebuilt.append(newItem)
            }
        }

        guard sawImageType else { return false }

        pb.clearContents()
        if !rebuilt.isEmpty {
            _ = pb.writeObjects(rebuilt)
        }

        lastSeenChangeCount = pb.changeCount
        log.clipboard("Removed image content from clipboard while preserving non-image types where possible")
        return true
    }

    static func interval(forIdleDuration seconds: TimeInterval) -> TimeInterval {
        if seconds >= 120 {
            return PollingProfile.idle.rawValue
        }
        if seconds >= 30 {
            return PollingProfile.warmIdle.rawValue
        }
        return PollingProfile.active.rawValue
    }

    static func hash(_ data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Private

    private func scheduleTimer(interval: TimeInterval) {
        timer?.invalidate()
        currentPollInterval = interval
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }

    private func maybeAdjustPollingInterval() {
        let idleDuration = Date().timeIntervalSince(lastChangeDate)
        let target = Self.interval(forIdleDuration: idleDuration)
        guard target != currentPollInterval else { return }
        scheduleTimer(interval: target)
        log.clipboard("Adaptive polling interval changed to \(String(format: "%.1f", target))s")
    }

    private func checkClipboard() {
        let pb = NSPasteboard.general
        let currentChangeCount = pb.changeCount

        if currentChangeCount == lastSeenChangeCount {
            maybeAdjustPollingInterval()
            return
        }

        lastSeenChangeCount = currentChangeCount
        lastChangeDate = Date()

        if currentPollInterval != PollingProfile.active.rawValue {
            scheduleTimer(interval: PollingProfile.active.rawValue)
        }

        guard !isWritingToPasteboard else {
            log.clipboard("Skipping: currently writing to pasteboard")
            return
        }

        guard let imageData = extractImageData(from: pb) else { return }

        let hash = sha256(imageData)
        guard hash != lastWrittenHash else {
            log.clipboard("Skipping: hash matches last written output")
            return
        }

        log.clipboard("New image detected on clipboard (\(ByteCountFormatter.string(fromByteCount: Int64(imageData.count), countStyle: .file)))")
        onImageDetected?(imageData)
    }

    private func extractImageData(from pb: NSPasteboard) -> Data? {
        let knownImageTypes: Set<NSPasteboard.PasteboardType> = [
            .png,
            .tiff,
            NSPasteboard.PasteboardType(UTType.jpeg.identifier),
            NSPasteboard.PasteboardType(UTType.gif.identifier),
            NSPasteboard.PasteboardType(UTType.bmp.identifier),
            NSPasteboard.PasteboardType(UTType.heic.identifier)
        ]

        let pbTypes = Set(pb.types ?? [])

        // Reject non-image content (PDFs, text, HTML, etc.) up front
        guard !pbTypes.isDisjoint(with: knownImageTypes) else { return nil }

        for type in knownImageTypes {
            if let data = pb.data(forType: type), !data.isEmpty {
                return data
            }
        }

        // Fallback: only for pasteboard items already confirmed to contain image types
        if let image = NSImage(pasteboard: pb),
           let tiff = image.tiffRepresentation {
            return tiff
        }

        if let urls = pb.readObjects(forClasses: [NSURL.self], options: [
            .urlReadingContentsConformToTypes: [UTType.image.identifier]
        ]) as? [URL], let url = urls.first {
            return try? Data(contentsOf: url)
        }

        return nil
    }

    private func isImagePasteboardType(_ type: NSPasteboard.PasteboardType) -> Bool {
        if type == .png || type == .tiff { return true }
        return UTType(type.rawValue)?.conforms(to: .image) ?? false
    }

    private func sha256(_ data: Data) -> String {
        Self.hash(data)
    }
}
