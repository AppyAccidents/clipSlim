import Foundation
import AppKit
import CryptoKit

@Observable
final class ClipboardWatcher {
    
    private(set) var isWatching = false
    private var timer: Timer?
    private var lastSeenChangeCount: Int = 0
    private var isWritingToPasteboard = false
    private var lastWrittenHash: String = ""
    
    private let pollInterval: TimeInterval = 0.5
    private let log = Logger.shared
    
    var onImageDetected: ((Data) -> Void)?
    
    func start() {
        guard !isWatching else { return }
        isWatching = true
        lastSeenChangeCount = NSPasteboard.general.changeCount
        log.clipboard("Clipboard watcher started (changeCount: \(lastSeenChangeCount))")
        
        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        isWatching = false
        log.clipboard("Clipboard watcher stopped")
    }
    
    func writeToPasteboard(data: Data, format: ImageFormat) {
        isWritingToPasteboard = true
        let pb = NSPasteboard.general
        pb.clearContents()
        
        let pasteboardType: NSPasteboard.PasteboardType = format == .png ? .png : .tiff
        pb.setData(data, forType: pasteboardType)
        
        lastSeenChangeCount = pb.changeCount
        lastWrittenHash = sha256(data)
        isWritingToPasteboard = false
        
        log.clipboard("Wrote optimized \(format.rawValue) to pasteboard (changeCount: \(lastSeenChangeCount))")
    }
    
    // MARK: - Private
    
    private func checkClipboard() {
        let pb = NSPasteboard.general
        let currentChangeCount = pb.changeCount
        
        // Layer 1: Skip if changeCount hasn't changed
        guard currentChangeCount != lastSeenChangeCount else { return }
        lastSeenChangeCount = currentChangeCount
        
        // Layer 2: Skip if we're currently writing
        guard !isWritingToPasteboard else {
            log.clipboard("Skipping: currently writing to pasteboard")
            return
        }
        
        // Extract image data from pasteboard
        guard let imageData = extractImageData(from: pb) else { return }
        
        // Layer 3: Skip if hash matches our last output
        let hash = sha256(imageData)
        guard hash != lastWrittenHash else {
            log.clipboard("Skipping: hash matches last written output")
            return
        }
        
        log.clipboard("New image detected on clipboard (\(ByteCountFormatter.string(fromByteCount: Int64(imageData.count), countStyle: .file)))")
        onImageDetected?(imageData)
    }
    
    private func extractImageData(from pb: NSPasteboard) -> Data? {
        // Try common image types in order of preference
        let imageTypes: [NSPasteboard.PasteboardType] = [.png, .tiff]
        
        for type in imageTypes {
            if let data = pb.data(forType: type), !data.isEmpty {
                return data
            }
        }
        
        // Try file URLs pointing to images
        if let urls = pb.readObjects(forClasses: [NSURL.self], options: [
            .urlReadingContentsConformToTypes: ["public.image"]
        ]) as? [URL], let url = urls.first {
            return try? Data(contentsOf: url)
        }
        
        return nil
    }
    
    private func sha256(_ data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
