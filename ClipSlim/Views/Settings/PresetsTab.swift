import SwiftUI

struct PresetsTab: View {

    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        VibeSettingsPage {
            VibeSettingsCard(title: "Preset", icon: "slider.horizontal.3") {
                Text("Active Preset")
                    .font(VibeCheckTheme.Typography.body)

                PresetButtonGroup(
                    selectedPreset: viewModel.settings.selectedPresetBinding,
                    labelStyle: .full,
                    selectedColor: VibeCheckTheme.Colors.neonOrange
                )

                presetDescription
            }

            VibeSettingsCard(title: "Optimization Intensity", icon: "bolt") {
                Picker("Optimization Intensity", selection: viewModel.settings.optimizationIntensityBinding) {
                    ForEach(OptimizationIntensity.allCases, id: \.self) { intensity in
                        Text(intensity.title).tag(intensity)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(viewModel.settings.selectedPreset != .custom)

                Text(viewModel.settings.optimizationIntensity.summary)
                    .font(VibeCheckTheme.Typography.caption)
                    .foregroundColor(VibeCheckTheme.Colors.textTertiary)
            }

            VibeSettingsCard(title: "Quality", icon: "dial.medium") {
                Toggle("Override preset quality", isOn: viewModel.settings.overridePresetQualityBinding)
                    .disabled(viewModel.settings.selectedPreset != .custom)

                HStack {
                    Text("JPEG Quality")
                    Spacer()
                    Text("\(Int(viewModel.settings.currentQuality * 100))%")
                        .font(VibeCheckTheme.Typography.monospacedBold)
                        .foregroundColor(VibeCheckTheme.Colors.neonCyan)
                }

                Slider(
                    value: editableQualityBinding,
                    in: 0.40...0.95,
                    step: 0.01
                )
                .disabled(viewModel.settings.selectedPreset != .custom)

                VibeHintText(text: "PNG output ignores quality setting.")
            }

            PipelineSection()
                .environment(viewModel)

            VibeSettingsCard(title: "Advanced", icon: "tuningfork") {
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

                Toggle("Strip Metadata (EXIF/GPS)", isOn: viewModel.settings.customStripMetadataBinding)
                    .disabled(viewModel.settings.selectedPreset != .custom)

                Toggle("Allow Transparency Loss", isOn: viewModel.settings.customAllowTransparencyLossBinding)
                    .disabled(viewModel.settings.selectedPreset != .custom)
            }
        }
    }

    private var presetDescription: some View {
        Group {
            switch viewModel.settings.selectedPreset {
            case .webQuality:
                Text("Optimized for web")
            case .highQuality:
                Text("Preserve quality")
            case .compressed:
                Text("Maximum compression")
            case .custom:
                Text("Use sliders below to tune")
            }
        }
        .font(VibeCheckTheme.Typography.caption)
        .foregroundColor(VibeCheckTheme.Colors.textTertiary)
    }

    private var editableQualityBinding: Binding<Double> {
        Binding(
            get: { viewModel.settings.currentQuality },
            set: { newValue in
                if viewModel.settings.selectedPreset == .custom {
                    viewModel.settings.customQuality = newValue
                } else {
                    viewModel.settings.overridePresetQuality = true
                    viewModel.settings.globalQualityValue = newValue
                }
            }
        )
    }
}
