import SwiftUI

struct AppMappingsTab: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var contextService = ContextAwareService()
    @State private var newBundleID = ""
    @State private var newAppName = ""
    @State private var newPreset: OptimizationPreset = .webQuality

    var body: some View {
        VibeSettingsPage {
            VibeSettingsCard(title: "App Rules", icon: "app.badge") {
                VibeHintText(text: "Map source apps to optimization presets. After 5 accepts, a rule auto-applies.")

                ForEach(contextService.mappings) { mapping in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(mapping.appName)
                                .font(VibeCheckTheme.Typography.body)
                            Text(mapping.bundleID)
                                .font(VibeCheckTheme.Typography.caption)
                                .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                        }
                        Spacer()
                        Text(mapping.preset)
                            .font(VibeCheckTheme.Typography.caption)
                            .foregroundColor(VibeCheckTheme.Colors.neonCyan)
                        if mapping.autoApply {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(VibeCheckTheme.Colors.neonOrange)
                                .font(.system(size: 10))
                        }
                        Button {
                            contextService.removeMapping(id: mapping.id, settings: viewModel.settings)
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 10))
                                .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 2)
                }
            }

            VibeSettingsCard(title: "Add Rule", icon: "plus.circle") {
                TextField("Bundle ID", text: $newBundleID)
                    .textFieldStyle(.roundedBorder)
                TextField("App Name", text: $newAppName)
                    .textFieldStyle(.roundedBorder)
                Picker("Preset", selection: $newPreset) {
                    ForEach(OptimizationPreset.allCases, id: \.self) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }
                Button("Add") {
                    guard !newBundleID.isEmpty, !newAppName.isEmpty else { return }
                    let mapping = AppPresetMapping(
                        bundleID: newBundleID,
                        appName: newAppName,
                        preset: newPreset.rawValue
                    )
                    contextService.addMapping(mapping, settings: viewModel.settings)
                    newBundleID = ""
                    newAppName = ""
                }
                .buttonStyle(.bordered)
            }
        }
        .onAppear {
            contextService.loadMappings(from: viewModel.settings)
        }
    }
}
