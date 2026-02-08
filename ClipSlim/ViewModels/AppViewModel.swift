import Foundation
import AppKit

@Observable
final class AppViewModel {
    
    let settings = AppSettings()
    let clipboardWatcher = ClipboardWatcher()
    let folderWatcher = FolderWatcher()
    
    private(set) var events: [OptimizationEvent] = []
    private(set) var totalSaved: Int = 0
    private(set) var totalOptimized: Int = 0
    private(set) var isProcessing = false
    private(set) var lastError: String?
    
    private let optimizer = ImageOptimizer.shared
    private let notificationService = NotificationService.shared
    private let log = Logger.shared
    
    init() {
        setupClipboardWatcher()
        setupFolderWatcher()
        notificationService.requestAuthorization()
    }
    
    // MARK: - Public
    
    func toggleClipboardWatch() {
        settings.clipboardWatchEnabled.toggle()
        if settings.clipboardWatchEnabled {
            clipboardWatcher.start()
        } else {
            clipboardWatcher.stop()
        }
    }
    
    func toggleFolderWatch() {
        settings.folderWatchEnabled.toggle()
        if settings.folderWatchEnabled {
            startFolderWatcher()
        } else {
            folderWatcher.stop()
        }
    }
    
    func startServices() {
        if settings.clipboardWatchEnabled {
            clipboardWatcher.start()
        }
        if settings.folderWatchEnabled {
            startFolderWatcher()
        }
    }
    
    func stopServices() {
        clipboardWatcher.stop()
        folderWatcher.stop()
    }
    
    func clearHistory() {
        events.removeAll()
        totalSaved = 0
        totalOptimized = 0
        log.app("Event history cleared")
    }
    
    func clearLastError() {
        lastError = nil
    }
    
    func optimizeManually(data: Data) {
        Task.detached { [weak self] in
            await self?.processImageData(data, source: .clipboard, fileName: nil)
        }
    }
    
    func selectWatchFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose a folder to watch for new images"
        panel.prompt = "Select Folder"
        
        if panel.runModal() == .OK, let url = panel.url {
            settings.watchedFolderPath = url.path
            if settings.folderWatchEnabled {
                folderWatcher.stop()
                startFolderWatcher()
            }
        }
    }
    
    // MARK: - Private Setup
    
    private func setupClipboardWatcher() {
        clipboardWatcher.onImageDetected = { [weak self] data in
            guard let self = self else { return }
            Task.detached {
                await self.processImageData(data, source: .clipboard, fileName: nil)
            }
        }
    }
    
    private func setupFolderWatcher() {
        folderWatcher.onFileDetected = { [weak self] url in
            guard let self = self else { return }
            Task.detached {
                await self.processFileURL(url)
            }
        }
    }
    
    private func startFolderWatcher() {
        guard !settings.watchedFolderPath.isEmpty else {
            log.folder("No folder path configured")
            return
        }
        folderWatcher.start(path: settings.watchedFolderPath)
    }
    
    // MARK: - Processing
    
    @MainActor
    private func processImageData(_ data: Data, source: OptimizationEvent.Source, fileName: String?) async {
        guard !isProcessing else {
            log.app("Already processing, skipping")
            return
        }
        
        isProcessing = true
        lastError = nil
        
        do {
            let config = ImageOptimizer.OptimizationConfig(from: settings)
            let (optimizedData, result) = try await optimizer.optimize(data: data, config: config)
            
            // Only write back if we actually saved space
            if result.optimizedSize < result.originalSize {
                if source == .clipboard {
                    clipboardWatcher.writeToPasteboard(data: optimizedData, format: result.format)
                }
                
                let event = OptimizationEvent(
                    timestamp: Date(),
                    source: source,
                    result: result,
                    fileName: fileName
                )
                events.insert(event, at: 0)
                
                // Keep only last 100 events
                if events.count > 100 {
                    events = Array(events.prefix(100))
                }
                
                totalSaved += result.savingsBytes
                totalOptimized += 1
                
                if settings.notificationsEnabled {
                    notificationService.sendOptimizationNotification(result: result, source: source)
                }
                
                log.app("Optimization complete: \(result.formattedOriginalSize) → \(result.formattedOptimizedSize) (\(String(format: "%.1f", result.savingsPercentage))%)")
            } else {
                log.app("Skipping: optimized version is not smaller (\(result.formattedOriginalSize) → \(result.formattedOptimizedSize))")
            }
            
        } catch {
            lastError = error.localizedDescription
            log.error("Optimization failed: \(error.localizedDescription)", category: "optimizer")
        }
        
        isProcessing = false
    }
    
    private func processFileURL(_ url: URL) async {
        do {
            let data = try Data(contentsOf: url)
            let config = ImageOptimizer.OptimizationConfig(from: settings)
            let (optimizedData, result) = try await optimizer.optimize(data: data, config: config)
            
            guard result.optimizedSize < result.originalSize else {
                log.folder("Skipping \(url.lastPathComponent): optimized is not smaller")
                return
            }
            
            // Build output filename
            let nameWithoutExt = url.deletingPathExtension().lastPathComponent
            let outputName = "\(nameWithoutExt)-optimized.\(result.format.fileExtension)"
            let outputURL = url.deletingLastPathComponent().appendingPathComponent(outputName)
            
            try optimizedData.write(to: outputURL, options: .atomic)
            
            let event = OptimizationEvent(
                timestamp: Date(),
                source: .folder,
                result: result,
                fileName: url.lastPathComponent
            )
            
            await MainActor.run {
                events.insert(event, at: 0)
                if events.count > 100 {
                    events = Array(events.prefix(100))
                }
                totalSaved += result.savingsBytes
                totalOptimized += 1
            }
            
            if settings.notificationsEnabled {
                notificationService.sendOptimizationNotification(result: result, source: .folder)
            }
            
            log.folder("Optimized \(url.lastPathComponent) → \(outputName)")
            
        } catch {
            log.error("Folder optimization failed for \(url.lastPathComponent): \(error.localizedDescription)", category: "folder")
        }
    }
}
