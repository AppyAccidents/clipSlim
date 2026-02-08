import Foundation
import SwiftUI

@Observable
final class AppSettings {
    @ObservationIgnored @AppStorage("clipboardWatchEnabled") var clipboardWatchEnabled = true
    @ObservationIgnored @AppStorage("folderWatchEnabled") var folderWatchEnabled = false
    @ObservationIgnored @AppStorage("notificationsEnabled") var notificationsEnabled = true
    @ObservationIgnored @AppStorage("selectedPreset") var selectedPreset = OptimizationPreset.web
    
    @ObservationIgnored @AppStorage("customQuality") var customQuality = 0.75
    @ObservationIgnored @AppStorage("customMaxDimension") var customMaxDimension = 1920
    @ObservationIgnored @AppStorage("customStripMetadata") var customStripMetadata = true
    @ObservationIgnored @AppStorage("customAllowTransparencyLoss") var customAllowTransparencyLoss = false
    
    @ObservationIgnored @AppStorage("watchedFolderPath") var watchedFolderPath = ""
    @ObservationIgnored @AppStorage("maxFileSizeMB") var maxFileSizeMB = 50
    @ObservationIgnored @AppStorage("launchAtLogin") var launchAtLogin = false
    @ObservationIgnored @AppStorage("saveToDisk") var saveToDisk = false
    @ObservationIgnored @AppStorage("saveFolderPath") var saveFolderPath = ""
    @ObservationIgnored @AppStorage("preferredOutputFormatRaw") var preferredOutputFormatRaw = ""
    
    var preferredOutputFormat: ImageFormat? {
        get {
            if preferredOutputFormatRaw.isEmpty { return nil }
            return ImageFormat(rawValue: preferredOutputFormatRaw)
        }
        set {
            preferredOutputFormatRaw = newValue?.rawValue ?? ""
        }
    }
    
    var currentQuality: Double {
        selectedPreset == .custom ? customQuality : selectedPreset.quality
    }
    
    var currentMaxDimension: Int {
        selectedPreset == .custom ? customMaxDimension : selectedPreset.maxDimension
    }
    
    var currentStripMetadata: Bool {
        selectedPreset == .custom ? customStripMetadata : selectedPreset.stripMetadata
    }
    
    var currentAllowTransparencyLoss: Bool {
        selectedPreset == .custom ? customAllowTransparencyLoss : selectedPreset.allowTransparencyLoss
    }
    
    // MARK: - Binding Helpers
    
    var clipboardWatchEnabledBinding: Binding<Bool> {
        Binding(get: { self.clipboardWatchEnabled }, set: { self.clipboardWatchEnabled = $0 })
    }
    var folderWatchEnabledBinding: Binding<Bool> {
        Binding(get: { self.folderWatchEnabled }, set: { self.folderWatchEnabled = $0 })
    }
    var notificationsEnabledBinding: Binding<Bool> {
        Binding(get: { self.notificationsEnabled }, set: { self.notificationsEnabled = $0 })
    }
    var selectedPresetBinding: Binding<OptimizationPreset> {
        Binding(get: { self.selectedPreset }, set: { self.selectedPreset = $0 })
    }
    var customQualityBinding: Binding<Double> {
        Binding(get: { self.customQuality }, set: { self.customQuality = $0 })
    }
    var customMaxDimensionBinding: Binding<Int> {
        Binding(get: { self.customMaxDimension }, set: { self.customMaxDimension = $0 })
    }
    var customStripMetadataBinding: Binding<Bool> {
        Binding(get: { self.customStripMetadata }, set: { self.customStripMetadata = $0 })
    }
    var customAllowTransparencyLossBinding: Binding<Bool> {
        Binding(get: { self.customAllowTransparencyLoss }, set: { self.customAllowTransparencyLoss = $0 })
    }
    var maxFileSizeMBBinding: Binding<Int> {
        Binding(get: { self.maxFileSizeMB }, set: { self.maxFileSizeMB = $0 })
    }
    var launchAtLoginBinding: Binding<Bool> {
        Binding(get: { self.launchAtLogin }, set: { self.launchAtLogin = $0 })
    }
    var saveToDiskBinding: Binding<Bool> {
        Binding(get: { self.saveToDisk }, set: { self.saveToDisk = $0 })
    }
    
    func applyPreset(_ preset: OptimizationPreset) {
        selectedPreset = preset
        if preset == .custom {
            return
        }
        customQuality = preset.quality
        customMaxDimension = preset.maxDimension
        customStripMetadata = preset.stripMetadata
        customAllowTransparencyLoss = preset.allowTransparencyLoss
    }
}
