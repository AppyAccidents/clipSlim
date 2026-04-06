import Foundation
import SwiftUI

enum MenuBarIconStyle: String, Codable, CaseIterable {
    case scissors
    case clipboard
    case weight

    var title: String {
        switch self {
        case .scissors: return "Scissors"
        case .clipboard: return "Clipboard"
        case .weight: return "Weight"
        }
    }

    var sfSymbolName: String {
        switch self {
        case .scissors: return "scissors"
        case .clipboard: return "doc.on.clipboard"
        case .weight: return "scalemass"
        }
    }
}

enum OptimizationIntensity: String, Codable, CaseIterable {
    case aggressive
    case moderate
    case light

    var title: String {
        switch self {
        case .aggressive: return "Aggressive"
        case .moderate: return "Moderate"
        case .light: return "Light"
        }
    }

    var summary: String {
        switch self {
        case .aggressive: return "Targets around 60% size reduction"
        case .moderate: return "Targets around 40% size reduction"
        case .light: return "Targets around 20% size reduction"
        }
    }

    var qualityValue: Double {
        switch self {
        case .aggressive: return 0.40
        case .moderate: return 0.60
        case .light: return 0.80
        }
    }
}

enum SaveDestinationMode: String, Codable, CaseIterable {
    case sameFolder
    case customFolder

    var title: String {
        switch self {
        case .sameFolder: return "Same folder as original"
        case .customFolder: return "Custom folder"
        }
    }
}

struct WatchedFolder: Codable, Identifiable, Hashable {
    let id: UUID
    var displayName: String
    var bookmarkData: Data

    init(id: UUID = UUID(), displayName: String, bookmarkData: Data) {
        self.id = id
        self.displayName = displayName
        self.bookmarkData = bookmarkData
    }
}

@Observable
final class AppSettings {
    static let onboardingSchemaVersion = 3

    @ObservationIgnored private let defaults: UserDefaults

    var clipboardWatchEnabled: Bool { didSet { defaults.set(clipboardWatchEnabled, forKey: Keys.clipboardWatchEnabled) } }
    var folderWatchEnabled: Bool { didSet { defaults.set(folderWatchEnabled, forKey: Keys.folderWatchEnabled) } }
    var notificationsEnabled: Bool { didSet { defaults.set(notificationsEnabled, forKey: Keys.notificationsEnabled) } }
    private var selectedPresetRaw: String { didSet { defaults.set(selectedPresetRaw, forKey: Keys.selectedPresetRaw) } }

    var customQuality: Double { didSet { defaults.set(customQuality, forKey: Keys.customQuality) } }
    var customMaxDimension: Int { didSet { defaults.set(customMaxDimension, forKey: Keys.customMaxDimension) } }
    var customStripMetadata: Bool { didSet { defaults.set(customStripMetadata, forKey: Keys.customStripMetadata) } }
    var customAllowTransparencyLoss: Bool { didSet { defaults.set(customAllowTransparencyLoss, forKey: Keys.customAllowTransparencyLoss) } }
    var metadataPolicyData: String { didSet { defaults.set(metadataPolicyData, forKey: Keys.metadataPolicyData) } }

    var maxFileSizeMB: Int { didSet { defaults.set(maxFileSizeMB, forKey: Keys.maxFileSizeMB) } }
    var launchAtLogin: Bool { didSet { defaults.set(launchAtLogin, forKey: Keys.launchAtLogin) } }
    var saveToDisk: Bool { didSet { defaults.set(saveToDisk, forKey: Keys.saveToDisk) } }
    var saveFolderPath: String { didSet { defaults.set(saveFolderPath, forKey: Keys.saveFolderPath) } }
    var saveDestinationModeRaw: String { didSet { defaults.set(saveDestinationModeRaw, forKey: Keys.saveDestinationModeRaw) } }

    var preferredOutputFormatRaw: String { didSet { defaults.set(preferredOutputFormatRaw, forKey: Keys.preferredOutputFormatRaw) } }
    var overridePresetQuality: Bool { didSet { defaults.set(overridePresetQuality, forKey: Keys.overridePresetQuality) } }
    var globalQualityValue: Double { didSet { defaults.set(globalQualityValue, forKey: Keys.globalQualityValue) } }
    var optimizationIntensityRaw: String { didSet { defaults.set(optimizationIntensityRaw, forKey: Keys.optimizationIntensityRaw) } }

    var onboardingCompleted: Bool { didSet { defaults.set(onboardingCompleted, forKey: Keys.onboardingCompleted) } }
    var onboardingPresentedAtLeastOnce: Bool { didSet { defaults.set(onboardingPresentedAtLeastOnce, forKey: Keys.onboardingPresentedAtLeastOnce) } }
    var onboardingSchemaVersionStored: Int { didSet { defaults.set(onboardingSchemaVersionStored, forKey: Keys.onboardingSchemaVersionStored) } }
    var pauseUntilEpoch: Double { didSet { defaults.set(pauseUntilEpoch, forKey: Keys.pauseUntilEpoch) } }
    var pauseFolderWatcher: Bool { didSet { defaults.set(pauseFolderWatcher, forKey: Keys.pauseFolderWatcher) } }

    var focusModeEnabled: Bool { didSet { defaults.set(focusModeEnabled, forKey: Keys.focusModeEnabled) } }
    var focusBundleIDsCSV: String { didSet { defaults.set(focusBundleIDsCSV, forKey: Keys.focusBundleIDsCSV) } }
    var excludedBundleIDsCSV: String { didSet { defaults.set(excludedBundleIDsCSV, forKey: Keys.excludedBundleIDsCSV) } }
    var menuBarIconStyleRaw: String { didSet { defaults.set(menuBarIconStyleRaw, forKey: Keys.menuBarIconStyleRaw) } }

    var pdfCompressionEnabled: Bool { didSet { defaults.set(pdfCompressionEnabled, forKey: Keys.pdfCompressionEnabled) } }
    var pdfTargetDPI: Int { didSet { defaults.set(pdfTargetDPI, forKey: Keys.pdfTargetDPI) } }
    var pdfImageQuality: Double { didSet { defaults.set(pdfImageQuality, forKey: Keys.pdfImageQuality) } }
    var pdfStripMetadata: Bool { didSet { defaults.set(pdfStripMetadata, forKey: Keys.pdfStripMetadata) } }
    var dropZoneVisibleOnLaunch: Bool { didSet { defaults.set(dropZoneVisibleOnLaunch, forKey: Keys.dropZoneVisibleOnLaunch) } }

    // F2: Smart Format
    var smartFormatEnabled: Bool { didSet { defaults.set(smartFormatEnabled, forKey: Keys.smartFormatEnabled) } }
    var webpPreferred: Bool { didSet { defaults.set(webpPreferred, forKey: Keys.webpPreferred) } }
    var avifPreferred: Bool { didSet { defaults.set(avifPreferred, forKey: Keys.avifPreferred) } }

    // F4: Pipeline Steps
    var enabledPipelineStepsRaw: String { didSet { defaults.set(enabledPipelineStepsRaw, forKey: Keys.enabledPipelineStepsRaw) } }

    // F8: Developer Mode
    var developerModeEnabled: Bool { didSet { defaults.set(developerModeEnabled, forKey: Keys.developerModeEnabled) } }

    // F3: Quality Guard
    var qualityGuardEnabled: Bool { didSet { defaults.set(qualityGuardEnabled, forKey: Keys.qualityGuardEnabled) } }
    var qualityGuardThreshold: Double { didSet { defaults.set(qualityGuardThreshold, forKey: Keys.qualityGuardThreshold) } }

    // F1: Context-Aware
    var appPresetMappingsData: String { didSet { defaults.set(appPresetMappingsData, forKey: Keys.appPresetMappingsData) } }

    // F9: Folder Rules
    var folderRulesData: String { didSet { defaults.set(folderRulesData, forKey: Keys.folderRulesData) } }

    private var watchedFoldersData: String { didSet { defaults.set(watchedFoldersData, forKey: Keys.watchedFoldersData) } }

    private enum Keys {
        static let clipboardWatchEnabled = "clipboardWatchEnabled"
        static let folderWatchEnabled = "folderWatchEnabled"
        static let notificationsEnabled = "notificationsEnabled"
        static let selectedPresetRaw = "selectedPreset"
        static let customQuality = "customQuality"
        static let customMaxDimension = "customMaxDimension"
        static let customStripMetadata = "customStripMetadata"
        static let customAllowTransparencyLoss = "customAllowTransparencyLoss"
        static let metadataPolicyData = "metadataPolicyData"
        static let maxFileSizeMB = "maxFileSizeMB"
        static let launchAtLogin = "launchAtLogin"
        static let saveToDisk = "saveToDisk"
        static let saveFolderPath = "saveFolderPath"
        static let saveDestinationModeRaw = "saveDestinationModeRaw"
        static let preferredOutputFormatRaw = "preferredOutputFormatRaw"
        static let overridePresetQuality = "overridePresetQuality"
        static let globalQualityValue = "globalQualityValue"
        static let optimizationIntensityRaw = "optimizationIntensityRaw"
        static let onboardingCompleted = "onboardingCompleted"
        static let onboardingPresentedAtLeastOnce = "onboardingPresentedAtLeastOnce"
        static let onboardingSchemaVersionStored = "onboardingSchemaVersion"
        static let pauseUntilEpoch = "pauseUntilEpoch"
        static let pauseFolderWatcher = "pauseFolderWatcher"
        static let focusModeEnabled = "focusModeEnabled"
        static let focusBundleIDsCSV = "focusBundleIDsCSV"
        static let excludedBundleIDsCSV = "excludedBundleIDsCSV"
        static let menuBarIconStyleRaw = "menuBarIconStyleRaw"
        static let watchedFoldersData = "watchedFoldersData"
        static let pdfCompressionEnabled = "pdfCompressionEnabled"
        static let pdfTargetDPI = "pdfTargetDPI"
        static let pdfImageQuality = "pdfImageQuality"
        static let pdfStripMetadata = "pdfStripMetadata"
        static let dropZoneVisibleOnLaunch = "dropZoneVisibleOnLaunch"
        static let smartFormatEnabled = "smartFormatEnabled"
        static let webpPreferred = "webpPreferred"
        static let avifPreferred = "avifPreferred"
        static let enabledPipelineStepsRaw = "enabledPipelineStepsRaw"
        static let developerModeEnabled = "developerModeEnabled"
        static let qualityGuardEnabled = "qualityGuardEnabled"
        static let qualityGuardThreshold = "qualityGuardThreshold"
        static let appPresetMappingsData = "appPresetMappingsData"
        static let folderRulesData = "folderRulesData"
    }

    // Chosen behavior: if preferred output is JPEG but input has alpha, force PNG.
    // This keeps alpha deterministic and avoids surprising flattening artifacts.
    let preserveAlphaByForcingPNG = true

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let storedPresetRaw = defaults.string(forKey: Keys.selectedPresetRaw) ?? OptimizationPreset.webQuality.rawValue
        let normalizedPresetRaw = Self.normalizeLegacyPresetRawValue(storedPresetRaw)
        clipboardWatchEnabled = defaults.object(forKey: Keys.clipboardWatchEnabled) as? Bool ?? true
        folderWatchEnabled = defaults.object(forKey: Keys.folderWatchEnabled) as? Bool ?? false
        notificationsEnabled = defaults.object(forKey: Keys.notificationsEnabled) as? Bool ?? true
        selectedPresetRaw = normalizedPresetRaw

        customQuality = defaults.object(forKey: Keys.customQuality) as? Double ?? 0.75
        customMaxDimension = defaults.object(forKey: Keys.customMaxDimension) as? Int ?? 1920
        customStripMetadata = defaults.object(forKey: Keys.customStripMetadata) as? Bool ?? true
        customAllowTransparencyLoss = defaults.object(forKey: Keys.customAllowTransparencyLoss) as? Bool ?? false
        metadataPolicyData = defaults.string(forKey: Keys.metadataPolicyData) ?? ""

        maxFileSizeMB = defaults.object(forKey: Keys.maxFileSizeMB) as? Int ?? 50
        launchAtLogin = defaults.object(forKey: Keys.launchAtLogin) as? Bool ?? false
        saveToDisk = defaults.object(forKey: Keys.saveToDisk) as? Bool ?? true
        saveFolderPath = defaults.string(forKey: Keys.saveFolderPath) ?? ""
        saveDestinationModeRaw = defaults.string(forKey: Keys.saveDestinationModeRaw) ?? SaveDestinationMode.customFolder.rawValue

        preferredOutputFormatRaw = defaults.string(forKey: Keys.preferredOutputFormatRaw) ?? ImageFormat.jpeg.rawValue
        overridePresetQuality = defaults.object(forKey: Keys.overridePresetQuality) as? Bool ?? false
        globalQualityValue = defaults.object(forKey: Keys.globalQualityValue) as? Double ?? 0.75
        optimizationIntensityRaw = defaults.string(forKey: Keys.optimizationIntensityRaw) ?? OptimizationIntensity.moderate.rawValue

        onboardingCompleted = defaults.object(forKey: Keys.onboardingCompleted) as? Bool ?? false
        onboardingPresentedAtLeastOnce = defaults.object(forKey: Keys.onboardingPresentedAtLeastOnce) as? Bool ?? false
        onboardingSchemaVersionStored = defaults.object(forKey: Keys.onboardingSchemaVersionStored) as? Int ?? 0
        pauseUntilEpoch = defaults.object(forKey: Keys.pauseUntilEpoch) as? Double ?? 0
        pauseFolderWatcher = defaults.object(forKey: Keys.pauseFolderWatcher) as? Bool ?? false

        focusModeEnabled = defaults.object(forKey: Keys.focusModeEnabled) as? Bool ?? false
        focusBundleIDsCSV = defaults.string(forKey: Keys.focusBundleIDsCSV) ?? "us.zoom.xos,com.microsoft.teams,com.microsoft.teams2"
        excludedBundleIDsCSV = defaults.string(forKey: Keys.excludedBundleIDsCSV) ?? ""
        menuBarIconStyleRaw = defaults.string(forKey: Keys.menuBarIconStyleRaw) ?? MenuBarIconStyle.scissors.rawValue

        watchedFoldersData = defaults.string(forKey: Keys.watchedFoldersData) ?? "[]"

        pdfCompressionEnabled = defaults.object(forKey: Keys.pdfCompressionEnabled) as? Bool ?? true
        pdfTargetDPI = defaults.object(forKey: Keys.pdfTargetDPI) as? Int ?? 150
        pdfImageQuality = defaults.object(forKey: Keys.pdfImageQuality) as? Double ?? 0.6
        pdfStripMetadata = defaults.object(forKey: Keys.pdfStripMetadata) as? Bool ?? true
        dropZoneVisibleOnLaunch = defaults.object(forKey: Keys.dropZoneVisibleOnLaunch) as? Bool ?? false

        smartFormatEnabled = defaults.object(forKey: Keys.smartFormatEnabled) as? Bool ?? false
        webpPreferred = defaults.object(forKey: Keys.webpPreferred) as? Bool ?? false
        avifPreferred = defaults.object(forKey: Keys.avifPreferred) as? Bool ?? false
        enabledPipelineStepsRaw = defaults.string(forKey: Keys.enabledPipelineStepsRaw) ?? PipelineStep.allCases.map(\.rawValue).joined(separator: ",")
        developerModeEnabled = defaults.object(forKey: Keys.developerModeEnabled) as? Bool ?? false
        qualityGuardEnabled = defaults.object(forKey: Keys.qualityGuardEnabled) as? Bool ?? true
        qualityGuardThreshold = defaults.object(forKey: Keys.qualityGuardThreshold) as? Double ?? 0.90
        appPresetMappingsData = defaults.string(forKey: Keys.appPresetMappingsData) ?? "[]"
        folderRulesData = defaults.string(forKey: Keys.folderRulesData) ?? "[]"

        if storedPresetRaw != normalizedPresetRaw {
            defaults.set(normalizedPresetRaw, forKey: Keys.selectedPresetRaw)
        }
    }

    var preferredOutputFormat: ImageFormat {
        get { ImageFormat(rawValue: preferredOutputFormatRaw) ?? .jpeg }
        set { preferredOutputFormatRaw = newValue.rawValue }
    }

    var watchedFolders: [WatchedFolder] {
        get { decodeArray(from: watchedFoldersData) }
        set { watchedFoldersData = encodeArray(newValue) }
    }

    var pauseUntil: Date? {
        get {
            guard pauseUntilEpoch > 0 else { return nil }
            return Date(timeIntervalSince1970: pauseUntilEpoch)
        }
        set {
            pauseUntilEpoch = newValue?.timeIntervalSince1970 ?? 0
        }
    }

    var isPausedNow: Bool {
        guard let pauseUntil else { return false }
        return Date() < pauseUntil
    }

    var focusBundleIDs: [String] {
        get {
            focusBundleIDsCSV
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        set {
            focusBundleIDsCSV = newValue.joined(separator: ",")
        }
    }

    var excludedBundleIDs: [String] {
        get {
            excludedBundleIDsCSV
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        set {
            excludedBundleIDsCSV = newValue.joined(separator: ",")
        }
    }

    var menuBarIconStyle: MenuBarIconStyle {
        get { MenuBarIconStyle(rawValue: menuBarIconStyleRaw) ?? .scissors }
        set { menuBarIconStyleRaw = newValue.rawValue }
    }

    var currentQuality: Double {
        if overridePresetQuality { return globalQualityValue }
        return selectedPreset == .custom ? customQuality : selectedPreset.quality
    }

    var currentSlimmingPercentage: Int {
        let percentage = Int(((1.0 - currentQuality) * 100.0).rounded())
        return max(0, min(100, percentage))
    }

    var selectedPreset: OptimizationPreset {
        get { OptimizationPreset(rawValue: Self.normalizeLegacyPresetRawValue(selectedPresetRaw)) ?? .webQuality }
        set { selectedPresetRaw = newValue.rawValue }
    }

    var saveDestinationMode: SaveDestinationMode {
        get { SaveDestinationMode(rawValue: saveDestinationModeRaw) ?? .customFolder }
        set { saveDestinationModeRaw = newValue.rawValue }
    }

    var optimizationIntensity: OptimizationIntensity {
        get { OptimizationIntensity(rawValue: optimizationIntensityRaw) ?? .moderate }
        set { optimizationIntensityRaw = newValue.rawValue }
    }

    var currentMaxDimension: Int {
        selectedPreset == .custom ? customMaxDimension : selectedPreset.maxDimension
    }

    var currentStripMetadata: Bool {
        selectedPreset == .custom ? customStripMetadata : selectedPreset.stripMetadata
    }

    var currentMetadataPolicy: MetadataPolicy {
        if !metadataPolicyData.isEmpty,
           let data = metadataPolicyData.data(using: .utf8),
           let policy = try? JSONDecoder().decode(MetadataPolicy.self, from: data) {
            return policy
        }
        return MetadataPolicy.fromLegacy(stripMetadata: currentStripMetadata)
    }

    func setMetadataPolicy(_ policy: MetadataPolicy) {
        if let data = try? JSONEncoder().encode(policy),
           let string = String(data: data, encoding: .utf8) {
            metadataPolicyData = string
        }
    }

    var currentAllowTransparencyLoss: Bool {
        selectedPreset == .custom ? customAllowTransparencyLoss : selectedPreset.allowTransparencyLoss
    }

    // MARK: - Pipeline Steps

    var enabledPipelineSteps: Set<PipelineStep> {
        get {
            let raw = enabledPipelineStepsRaw
                .split(separator: ",")
                .compactMap { PipelineStep(rawValue: String($0)) }
            return Set(raw)
        }
        set {
            enabledPipelineStepsRaw = newValue.map(\.rawValue).joined(separator: ",")
        }
    }

    func isPipelineStepEnabled(_ step: PipelineStep) -> Bool {
        enabledPipelineSteps.contains(step)
    }

    func togglePipelineStep(_ step: PipelineStep) {
        var steps = enabledPipelineSteps
        if steps.contains(step) {
            steps.remove(step)
        } else {
            steps.insert(step)
        }
        enabledPipelineSteps = steps
    }

    // MARK: - New Settings Bindings

    var smartFormatEnabledBinding: Binding<Bool> {
        Binding(get: { self.smartFormatEnabled }, set: { self.smartFormatEnabled = $0 })
    }
    var webpPreferredBinding: Binding<Bool> {
        Binding(get: { self.webpPreferred }, set: { self.webpPreferred = $0 })
    }
    var avifPreferredBinding: Binding<Bool> {
        Binding(get: { self.avifPreferred }, set: { self.avifPreferred = $0 })
    }
    var developerModeEnabledBinding: Binding<Bool> {
        Binding(get: { self.developerModeEnabled }, set: { self.developerModeEnabled = $0 })
    }
    var qualityGuardEnabledBinding: Binding<Bool> {
        Binding(get: { self.qualityGuardEnabled }, set: { self.qualityGuardEnabled = $0 })
    }
    var qualityGuardThresholdBinding: Binding<Double> {
        Binding(get: { self.qualityGuardThreshold }, set: { self.qualityGuardThreshold = $0 })
    }

    var shouldPresentOnboarding: Bool {
        if !onboardingPresentedAtLeastOnce { return true }
        if !onboardingCompleted { return true }
        if onboardingSchemaVersionStored < Self.onboardingSchemaVersion { return true }
        if preferredOutputFormatRaw.isEmpty { return true }
        return false
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
        Binding(get: { self.selectedPreset }, set: { self.applyPreset($0) })
    }
    var customQualityBinding: Binding<Double> {
        Binding(get: { self.customQuality }, set: { self.customQuality = $0 })
    }
    var globalQualityValueBinding: Binding<Double> {
        Binding(get: { self.globalQualityValue }, set: { self.globalQualityValue = $0 })
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
    var saveDestinationModeBinding: Binding<SaveDestinationMode> {
        Binding(get: { self.saveDestinationMode }, set: { self.saveDestinationMode = $0 })
    }
    var overridePresetQualityBinding: Binding<Bool> {
        Binding(get: { self.overridePresetQuality }, set: { self.overridePresetQuality = $0 })
    }
    var focusModeEnabledBinding: Binding<Bool> {
        Binding(get: { self.focusModeEnabled }, set: { self.focusModeEnabled = $0 })
    }
    var pauseFolderWatcherBinding: Binding<Bool> {
        Binding(get: { self.pauseFolderWatcher }, set: { self.pauseFolderWatcher = $0 })
    }
    var menuBarIconStyleBinding: Binding<MenuBarIconStyle> {
        Binding(get: { self.menuBarIconStyle }, set: { self.menuBarIconStyle = $0 })
    }
    var optimizationIntensityBinding: Binding<OptimizationIntensity> {
        Binding(
            get: { self.optimizationIntensity },
            set: { self.applyOptimizationIntensity($0) }
        )
    }
    var pdfCompressionEnabledBinding: Binding<Bool> {
        Binding(get: { self.pdfCompressionEnabled }, set: { self.pdfCompressionEnabled = $0 })
    }
    var pdfTargetDPIBinding: Binding<Int> {
        Binding(get: { self.pdfTargetDPI }, set: { self.pdfTargetDPI = $0 })
    }
    var pdfImageQualityBinding: Binding<Double> {
        Binding(get: { self.pdfImageQuality }, set: { self.pdfImageQuality = $0 })
    }
    var pdfStripMetadataBinding: Binding<Bool> {
        Binding(get: { self.pdfStripMetadata }, set: { self.pdfStripMetadata = $0 })
    }
    var dropZoneVisibleOnLaunchBinding: Binding<Bool> {
        Binding(get: { self.dropZoneVisibleOnLaunch }, set: { self.dropZoneVisibleOnLaunch = $0 })
    }

    func applyPreset(_ preset: OptimizationPreset) {
        selectedPreset = preset
        overridePresetQuality = false
    }

    func applyOptimizationIntensity(_ intensity: OptimizationIntensity) {
        optimizationIntensity = intensity
        selectedPreset = .custom
        overridePresetQuality = false
        customQuality = intensity.qualityValue
        globalQualityValue = intensity.qualityValue
    }

    func markOnboardingCompleted() {
        onboardingCompleted = true
        onboardingSchemaVersionStored = Self.onboardingSchemaVersion
    }

    func markOnboardingPresented() {
        onboardingPresentedAtLeastOnce = true
    }

    private func encodeArray<T: Codable>(_ value: [T]) -> String {
        guard let data = try? JSONEncoder().encode(value),
              let string = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return string
    }

    private func decodeArray<T: Codable>(from raw: String) -> [T] {
        guard let data = raw.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([T].self, from: data) else {
            return []
        }
        return decoded
    }

    // MARK: - Video/GIF Settings (v2.0 stubs — full UI in Task 8-10)

    var videoCodecRaw: String {
        UserDefaults.standard.string(forKey: "videoCodecRaw") ?? "H.264"
    }

    var videoQuality: Double {
        let val = UserDefaults.standard.double(forKey: "videoQuality")
        return val > 0 ? val : 0.7
    }

    var videoMaxResolution: Int {
        let val = UserDefaults.standard.integer(forKey: "videoMaxResolution")
        return val > 0 ? val : 1080
    }

    var videoStripMetadata: Bool {
        if UserDefaults.standard.object(forKey: "videoStripMetadata") != nil {
            return UserDefaults.standard.bool(forKey: "videoStripMetadata")
        }
        return true
    }

    var gifMaxColors: Int {
        let val = UserDefaults.standard.integer(forKey: "gifMaxColors")
        return val > 0 ? val : 256
    }

    var gifFrameSkip: Int {
        UserDefaults.standard.integer(forKey: "gifFrameSkip")
    }

    var gifMaxDimension: Int {
        let val = UserDefaults.standard.integer(forKey: "gifMaxDimension")
        return val > 0 ? val : 480
    }

    var videoToGifFPS: Int {
        let val = UserDefaults.standard.integer(forKey: "videoToGifFPS")
        return val > 0 ? val : 10
    }

    private static func normalizeLegacyPresetRawValue(_ raw: String) -> String {
        switch raw {
        case "Web":
            return OptimizationPreset.webQuality.rawValue
        case "High Quality":
            return OptimizationPreset.highQuality.rawValue
        case "Small":
            return OptimizationPreset.compressed.rawValue
        default:
            return raw
        }
    }
}
