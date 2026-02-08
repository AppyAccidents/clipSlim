import SwiftUI

struct PresetsTab: View {
    
    @Environment(AppViewModel.self) private var viewModel
    
    var body: some View {
        Form {
            Section {
                Picker("Active Preset", selection: viewModel.settings.selectedPresetBinding) {
                    ForEach(OptimizationPreset.allCases, id: \.self) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }
                .pickerStyle(.segmented)
                
                presetDescription
            } header: {
                Label("Preset", systemImage: "slider.horizontal.3")
            }
            
            Section {
                VStack(alignment: .leading, spacing: VibeCheckTheme.Spacing.sm) {
                    HStack {
                        Text("Quality")
                        Spacer()
                        Text("\(Int(viewModel.settings.currentQuality * 100))%")
                            .font(VibeCheckTheme.Typography.monospacedBold)
                            .foregroundColor(VibeCheckTheme.Colors.neonCyan)
                    }
                    Slider(value: viewModel.settings.customQualityBinding, in: 0.1...1.0, step: 0.05)
                        .disabled(viewModel.settings.selectedPreset != .custom)
                }
                
                VStack(alignment: .leading, spacing: VibeCheckTheme.Spacing.sm) {
                    HStack {
                        Text("Max Dimension")
                        Spacer()
                        Text("\(viewModel.settings.currentMaxDimension)px")
                            .font(VibeCheckTheme.Typography.monospacedBold)
                            .foregroundColor(VibeCheckTheme.Colors.neonCyan)
                    }
                    Slider(
                        value: Binding(
                            get: { Double(viewModel.settings.customMaxDimension) },
                            set: { viewModel.settings.customMaxDimension = Int($0) }
                        ),
                        in: 640...7680,
                        step: 160
                    )
                    .disabled(viewModel.settings.selectedPreset != .custom)
                }
                
                Toggle("Strip Metadata (EXIF/GPS)", isOn: viewModel.settings.customStripMetadataBinding)
                    .disabled(viewModel.settings.selectedPreset != .custom)
                
                Toggle("Allow Transparency Loss", isOn: viewModel.settings.customAllowTransparencyLossBinding)
                    .disabled(viewModel.settings.selectedPreset != .custom)
                
                if !viewModel.settings.currentAllowTransparencyLoss {
                    Text("Transparent PNGs will stay as PNG even when JPEG output is preferred")
                        .font(VibeCheckTheme.Typography.caption)
                        .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                }
            } header: {
                Label("Advanced", systemImage: "tuningfork")
            }
        }
        .formStyle(.grouped)
    }
    
    private var presetDescription: some View {
        Group {
            switch viewModel.settings.selectedPreset {
            case .web:
                Text("Optimized for web — 75% quality, max 1920px, metadata stripped")
            case .highQuality:
                Text("Preserve quality — 90% quality, max 3840px, metadata kept")
            case .small:
                Text("Maximum compression — 60% quality, max 1280px, metadata stripped")
            case .custom:
                Text("Use the sliders below to fine-tune your settings")
            }
        }
        .font(VibeCheckTheme.Typography.caption)
        .foregroundColor(VibeCheckTheme.Colors.textTertiary)
    }
}
