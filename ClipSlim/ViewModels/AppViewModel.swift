import Foundation
import AppKit
import Carbon.HIToolbox

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
    
    private(set) var lastOriginalData: Data?
    private(set) var lastOptimizedData: Data?
    private(set) var lastOptimizedFormat: ImageFormat = .jpeg
    
    private let optimizer = ImageOptimizer.shared
    private let notificationService = NotificationService.shared
    private let log = Logger.shared
    
    private var hotKeyRef1: EventHotKeyRef?
    private var hotKeyRef2: EventHotKeyRef?
<<<<<<< /Users/berkerceylan/Documents/GitHub/clipSlim/ClipSlim/ViewModels/AppViewModel.swift
=======
    private var imageCacheTimer: Timer?
    private let imageCacheTimeout: TimeInterval = 300 // 5 minutes
>>>>>>> /Users/berkerceylan/.windsurf/worktrees/clipSlim/clipSlim-d1f4857c/ClipSlim/ViewModels/AppViewModel.swift
    
    init() {
        setupClipboardWatcher()
        setupFolderWatcher()
        notificationService.requestAuthorization()
        registerGlobalHotkeys()
<<<<<<< /Users/berkerceylan/Documents/GitHub/clipSlim/ClipSlim/ViewModels/AppViewModel.swift
=======
    }
    
    deinit {
        imageCacheTimer?.invalidate()
>>>>>>> /Users/berkerceylan/.windsurf/worktrees/clipSlim/clipSlim-d1f4857c/ClipSlim/ViewModels/AppViewModel.swift
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
    
    func copyLastOptimized() {
        guard let data = lastOptimizedData else {
            log.app("No optimized image available")
            return
        }
        clipboardWatcher.writeToPasteboard(data: data, format: lastOptimizedFormat)
        log.app("Copied last optimized image to clipboard (⌥1)")
    }
    
    func copyLastOriginal() {
        guard let data = lastOriginalData else {
            log.app("No original image available")
            return
        }
        clipboardWatcher.writeToPasteboard(data: data, format: .png)
        log.app("Copied last original image to clipboard (⌥2)")
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
    
    // MARK: - Global Hotkeys
    
    private func registerGlobalHotkeys() {
        let viewModelPtr = Unmanaged.passUnretained(self).toOpaque()
        
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        InstallEventHandler(GetApplicationEventTarget(), { _, event, userData -> OSStatus in
            guard let event = event, let userData = userData else { return OSStatus(eventNotHandledErr) }
            var hotKeyID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
            
            let vm = Unmanaged<AppViewModel>.fromOpaque(userData).takeUnretainedValue()
            
            DispatchQueue.main.async {
                switch hotKeyID.id {
                case 1:
                    vm.copyLastOptimized()
                case 2:
                    vm.copyLastOriginal()
                default:
                    break
                }
            }
            return noErr
        }, 1, &eventType, viewModelPtr, nil)
        
        // ⌥1 (Option+1) — copy last optimized
        var hotKeyID1 = EventHotKeyID(signature: OSType(0x434C5031), id: 1) // "CLP1"
        RegisterEventHotKey(UInt32(kVK_ANSI_1), UInt32(optionKey), hotKeyID1, GetApplicationEventTarget(), 0, &hotKeyRef1)
        
        // ⌥2 (Option+2) — copy last original
        var hotKeyID2 = EventHotKeyID(signature: OSType(0x434C5032), id: 2) // "CLP2"
        RegisterEventHotKey(UInt32(kVK_ANSI_2), UInt32(optionKey), hotKeyID2, GetApplicationEventTarget(), 0, &hotKeyRef2)
        
        log.app("Global hotkeys registered: ⌥1 (optimized), ⌥2 (original)")
    }
    
<<<<<<< /Users/berkerceylan/Documents/GitHub/clipSlim/ClipSlim/ViewModels/AppViewModel.swift
=======
    // MARK: - Memory Management
    
    private func scheduleImageCacheCleanup() {
        imageCacheTimer?.invalidate()
        imageCacheTimer = Timer.scheduledTimer(withTimeInterval: imageCacheTimeout, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.clearImageCache()
            }
        }
    }
    
    private func clearImageCache() {
        let hadData = lastOriginalData != nil || lastOptimizedData != nil
        lastOriginalData = nil
        lastOptimizedData = nil
        if hadData {
            log.app("Cleared cached images (memory optimization)")
        }
    }
    
>>>>>>> /Users/berkerceylan/.windsurf/worktrees/clipSlim/clipSlim-d1f4857c/ClipSlim/ViewModels/AppViewModel.swift
    // MARK: - Save to Disk
    
    private func saveToDisk(originalData: Data, optimizedData: Data, format: ImageFormat, fileName: String?) {
        guard settings.saveToDisk else { return }
        
        let basePath: String
        if settings.saveFolderPath.isEmpty {
            let pictures = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first!
            basePath = pictures.appendingPathComponent("ClipSlim").path
        } else {
            basePath = settings.saveFolderPath
        }
        
        let originalsDir = (basePath as NSString).appendingPathComponent("Originals")
        let optimizedDir = (basePath as NSString).appendingPathComponent("Optimized")
        
        do {
            try FileManager.default.createDirectory(atPath: originalsDir, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(atPath: optimizedDir, withIntermediateDirectories: true)
            
            let timestamp = ISO8601DateFormatter().string(from: Date())
                .replacingOccurrences(of: ":", with: "-")
            let baseName = fileName ?? "clipboard-\(timestamp)"
            let nameWithoutExt = (baseName as NSString).deletingPathExtension
            let origExt = (baseName as NSString).pathExtension.isEmpty ? "png" : (baseName as NSString).pathExtension
            
            let originalPath = (originalsDir as NSString).appendingPathComponent("\(nameWithoutExt).\(origExt)")
            let optimizedPath = (optimizedDir as NSString).appendingPathComponent("\(nameWithoutExt).\(format.fileExtension)")
            
            try originalData.write(to: URL(fileURLWithPath: originalPath), options: .atomic)
            try optimizedData.write(to: URL(fileURLWithPath: optimizedPath), options: .atomic)
            
            log.app("Saved original to \(originalPath)")
            log.app("Saved optimized to \(optimizedPath)")
        } catch {
            log.error("Failed to save to disk: \(error.localizedDescription)")
        }
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
            
<<<<<<< /Users/berkerceylan/Documents/GitHub/clipSlim/ClipSlim/ViewModels/AppViewModel.swift
            // Store last original and optimized for hotkey access
            lastOriginalData = data
            lastOptimizedData = optimizedData
            lastOptimizedFormat = result.format
=======
            // Store last original and optimized for hotkey access (with auto-cleanup)
            lastOriginalData = data
            lastOptimizedData = optimizedData
            lastOptimizedFormat = result.format
            scheduleImageCacheCleanup()
>>>>>>> /Users/berkerceylan/.windsurf/worktrees/clipSlim/clipSlim-d1f4857c/ClipSlim/ViewModels/AppViewModel.swift
            
            // Only write back if we actually saved space
            if result.optimizedSize < result.originalSize {
                if source == .clipboard {
                    clipboardWatcher.writeToPasteboard(data: optimizedData, format: result.format)
                }
                
                // Save to disk if enabled
                saveToDisk(originalData: data, optimizedData: optimizedData, format: result.format, fileName: fileName)
                
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
            
<<<<<<< /Users/berkerceylan/Documents/GitHub/clipSlim/ClipSlim/ViewModels/AppViewModel.swift
            // Store last original and optimized for hotkey access
=======
            // Store last original and optimized for hotkey access (with auto-cleanup)
>>>>>>> /Users/berkerceylan/.windsurf/worktrees/clipSlim/clipSlim-d1f4857c/ClipSlim/ViewModels/AppViewModel.swift
            await MainActor.run {
                lastOriginalData = data
                lastOptimizedData = optimizedData
                lastOptimizedFormat = result.format
<<<<<<< /Users/berkerceylan/Documents/GitHub/clipSlim/ClipSlim/ViewModels/AppViewModel.swift
=======
                scheduleImageCacheCleanup()
>>>>>>> /Users/berkerceylan/.windsurf/worktrees/clipSlim/clipSlim-d1f4857c/ClipSlim/ViewModels/AppViewModel.swift
            }
            
            // Build output filename
            let nameWithoutExt = url.deletingPathExtension().lastPathComponent
            let outputName = "\(nameWithoutExt)-optimized.\(result.format.fileExtension)"
            let outputURL = url.deletingLastPathComponent().appendingPathComponent(outputName)
            
            try optimizedData.write(to: outputURL, options: .atomic)
            
            // Save to disk if enabled
            saveToDisk(originalData: data, optimizedData: optimizedData, format: result.format, fileName: url.lastPathComponent)
            
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
