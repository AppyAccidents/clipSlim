import Foundation
import AppKit

@MainActor
@Observable
final class ContextAwareService {
    private(set) var mappings: [AppPresetMapping] = []
    private let log = Logger.shared

    init() {
        loadMappings()
    }

    func loadMappings(from settings: AppSettings? = nil) {
        guard let settings else {
            mappings = AppPresetMapping.defaults
            return
        }
        let data = settings.appPresetMappingsData
        guard let jsonData = data.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([AppPresetMapping].self, from: jsonData),
              !decoded.isEmpty else {
            mappings = AppPresetMapping.defaults
            return
        }
        mappings = decoded
    }

    func saveMappings(to settings: AppSettings) {
        guard let data = try? JSONEncoder().encode(mappings),
              let json = String(data: data, encoding: .utf8) else { return }
        settings.appPresetMappingsData = json
    }

    func suggestedPreset(for bundleID: String) -> (preset: OptimizationPreset, autoApply: Bool)? {
        guard let mapping = mappings.first(where: { $0.bundleID == bundleID }) else { return nil }
        guard let preset = OptimizationPreset(rawValue: mapping.preset) else { return nil }
        return (preset, mapping.autoApply)
    }

    func recordAccept(for bundleID: String, settings: AppSettings) {
        guard let index = mappings.firstIndex(where: { $0.bundleID == bundleID }) else { return }
        mappings[index].acceptCount += 1
        if mappings[index].acceptCount >= 5 {
            mappings[index].autoApply = true
        }
        saveMappings(to: settings)
    }

    func recordDismiss(for bundleID: String, settings: AppSettings) {
        guard let index = mappings.firstIndex(where: { $0.bundleID == bundleID }) else { return }
        mappings[index].dismissCount += 1
        saveMappings(to: settings)
    }

    func addMapping(_ mapping: AppPresetMapping, settings: AppSettings) {
        mappings.append(mapping)
        saveMappings(to: settings)
    }

    func removeMapping(id: UUID, settings: AppSettings) {
        mappings.removeAll { $0.id == id }
        saveMappings(to: settings)
    }

    func updateMapping(id: UUID, preset: OptimizationPreset, settings: AppSettings) {
        guard let index = mappings.firstIndex(where: { $0.id == id }) else { return }
        mappings[index].preset = preset.rawValue
        saveMappings(to: settings)
    }
}
