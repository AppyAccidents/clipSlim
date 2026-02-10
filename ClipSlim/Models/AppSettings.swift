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
    static let onboardingSchemaVersion = 2

    @ObservationIgnored private let defaults: UserDefaults

    var clipboardWatchEnabled: Bool { didSet { defaults.set(clipboardWatchEnabled, forKey: Keys.clipboardWatchEnabled) } }
    var folderWatchEnabled: Bool { didSet { defaults.set(folderWatchEnabled, forKey: Keys.folderWatchEnabled) } }
    var notificationsEnabled: Bool { didSet { defaults.set(notificationsEnabled, forKey: Keys.notificationsEnabled) } }
    private var selectedPresetRaw: String { didSet { defaults.set(selectedPresetRaw, forKey: Keys.selectedPresetRaw) } }

    var customQuality: Double { didSet { defaults.set(customQuality, forKey: Keys.customQuality) } }
    var customMaxDimension: Int { didSet { defaults.set(customMaxDimension, forKey: Keys.customMaxDimension) } }
    var customStripMetadata: Bool { didSet { defaults.set(customStripMetadata, forKey: Keys.customStripMetadata) } }
    var customAllowTransparencyLoss: Bool { didSet { defaults.set(customAllowTransparencyLoss, forKey: Keys.customAllowTransparencyLoss) } }

    var maxFileSizeMB: Int { didSet { defaults.set(maxFileSizeMB, forKey: Keys.maxFileSizeMB) } }
    var launchAtLogin: Bool { didSet { defaults.set(launchAtLogin, forKey: Keys.launchAtLogin) } }
    var saveToDisk: Bool { didSet { defaults.set(saveToDisk, forKey: Keys.saveToDisk) } }
    var saveFolderPath: String { didSet { defaults.set(saveFolderPath, forKey: Keys.saveFolderPath) } }

    var preferredOutputFormatRaw: String { didSet { defaults.set(preferredOutputFormatRaw, forKey: Keys.preferredOutputFormatRaw) } }
    var overridePresetQuality: Bool { didSet { defaults.set(overridePresetQuality, forKey: Keys.overridePresetQuality) } }
    var globalQualityValue: Double { didSet { defaults.set(globalQualityValue, forKey: Keys.globalQualityValue) } }
    var optimizationIntensityRaw: String { didSet { defaults.set(optimizationIntensityRaw, forKey: Keys.optimizationIntensityRaw) } }

    var onboardingCompleted: Bool { didSet { defaults.set(onboardingCompleted, forKey: Keys.onboardingCompleted) } }
    var onboardingSchemaVersionStored: Int { didSet { defaults.set(onboardingSchemaVersionStored, forKey: Keys.onboardingSchemaVersionStored) } }
    var pauseUntilEpoch: Double { didSet { defaults.set(pauseUntilEpoch, forKey: Keys.pauseUntilEpoch) } }
    var pauseFolderWatcher: Bool { didSet { defaults.set(pauseFolderWatcher, forKey: Keys.pauseFolderWatcher) } }

    var focusModeEnabled: Bool { didSet { defaults.set(focusModeEnabled, forKey: Keys.focusModeEnabled) } }
    var focusBundleIDsCSV: String { didSet { defaults.set(focusBundleIDsCSV, forKey: Keys.focusBundleIDsCSV) } }
    var excludedBundleIDsCSV: String { didSet { defaults.set(excludedBundleIDsCSV, forKey: Keys.excludedBundleIDsCSV) } }
    var menuBarIconStyleRaw: String { didSet { defaults.set(menuBarIconStyleRaw, forKey: Keys.menuBarIconStyleRaw) } }
    var lastDonationPromptEpoch: Double { didSet { defaults.set(lastDonationPromptEpoch, forKey: Keys.lastDonationPromptEpoch) } }

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
        static let maxFileSizeMB = "maxFileSizeMB"
        static let launchAtLogin = "launchAtLogin"
        static let saveToDisk = "saveToDisk"
        static let saveFolderPath = "saveFolderPath"
        static let preferredOutputFormatRaw = "preferredOutputFormatRaw"
        static let overridePresetQuality = "overridePresetQuality"
        static let globalQualityValue = "globalQualityValue"
        static let optimizationIntensityRaw = "optimizationIntensityRaw"
        static let onboardingCompleted = "onboardingCompleted"
        static let onboardingSchemaVersionStored = "onboardingSchemaVersion"
        static let pauseUntilEpoch = "pauseUntilEpoch"
        static let pauseFolderWatcher = "pauseFolderWatcher"
        static let focusModeEnabled = "focusModeEnabled"
        static let focusBundleIDsCSV = "focusBundleIDsCSV"
        static let excludedBundleIDsCSV = "excludedBundleIDsCSV"
        static let menuBarIconStyleRaw = "menuBarIconStyleRaw"
        static let lastDonationPromptEpoch = "lastDonationPromptEpoch"
        static let watchedFoldersData = "watchedFoldersData"
    }

    // Chosen behavior: if preferred output is JPEG but input has alpha, force PNG.
    // This keeps alpha deterministic and avoids surprising flattening artifacts.
    let preserveAlphaByForcingPNG = true

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        clipboardWatchEnabled = defaults.object(forKey: Keys.clipboardWatchEnabled) as? Bool ?? true
        folderWatchEnabled = defaults.object(forKey: Keys.folderWatchEnabled) as? Bool ?? false
        notificationsEnabled = defaults.object(forKey: Keys.notificationsEnabled) as? Bool ?? true
        selectedPresetRaw = defaults.string(forKey: Keys.selectedPresetRaw) ?? OptimizationPreset.web.rawValue

        customQuality = defaults.object(forKey: Keys.customQuality) as? Double ?? 0.75
        customMaxDimension = defaults.object(forKey: Keys.customMaxDimension) as? Int ?? 1920
        customStripMetadata = defaults.object(forKey: Keys.customStripMetadata) as? Bool ?? true
        customAllowTransparencyLoss = defaults.object(forKey: Keys.customAllowTransparencyLoss) as? Bool ?? false

        maxFileSizeMB = defaults.object(forKey: Keys.maxFileSizeMB) as? Int ?? 50
        launchAtLogin = defaults.object(forKey: Keys.launchAtLogin) as? Bool ?? false
        saveToDisk = defaults.object(forKey: Keys.saveToDisk) as? Bool ?? true
        saveFolderPath = defaults.string(forKey: Keys.saveFolderPath) ?? ""

        preferredOutputFormatRaw = defaults.string(forKey: Keys.preferredOutputFormatRaw) ?? ImageFormat.jpeg.rawValue
        overridePresetQuality = defaults.object(forKey: Keys.overridePresetQuality) as? Bool ?? false
        globalQualityValue = defaults.object(forKey: Keys.globalQualityValue) as? Double ?? 0.75
        optimizationIntensityRaw = defaults.string(forKey: Keys.optimizationIntensityRaw) ?? OptimizationIntensity.moderate.rawValue

        onboardingCompleted = defaults.object(forKey: Keys.onboardingCompleted) as? Bool ?? false
        onboardingSchemaVersionStored = defaults.object(forKey: Keys.onboardingSchemaVersionStored) as? Int ?? 0
        pauseUntilEpoch = defaults.object(forKey: Keys.pauseUntilEpoch) as? Double ?? 0
        pauseFolderWatcher = defaults.object(forKey: Keys.pauseFolderWatcher) as? Bool ?? false

        focusModeEnabled = defaults.object(forKey: Keys.focusModeEnabled) as? Bool ?? false
        focusBundleIDsCSV = defaults.string(forKey: Keys.focusBundleIDsCSV) ?? "us.zoom.xos,com.microsoft.teams,com.microsoft.teams2"
        excludedBundleIDsCSV = defaults.string(forKey: Keys.excludedBundleIDsCSV) ?? ""
        menuBarIconStyleRaw = defaults.string(forKey: Keys.menuBarIconStyleRaw) ?? MenuBarIconStyle.scissors.rawValue
        lastDonationPromptEpoch = defaults.object(forKey: Keys.lastDonationPromptEpoch) as? Double ?? 0

        watchedFoldersData = defaults.string(forKey: Keys.watchedFoldersData) ?? "[]"
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

    var selectedPreset: OptimizationPreset {
        get { OptimizationPreset(rawValue: selectedPresetRaw) ?? .web }
        set { selectedPresetRaw = newValue.rawValue }
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

    var currentAllowTransparencyLoss: Bool {
        selectedPreset == .custom ? customAllowTransparencyLoss : selectedPreset.allowTransparencyLoss
    }

    var shouldPresentOnboarding: Bool {
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
}
