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

                metadataPolicySection

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
            case .lossless:
                Text("Strip metadata only, no quality loss")
            }
        }
        .font(VibeCheckTheme.Typography.caption)
        .foregroundColor(VibeCheckTheme.Colors.textTertiary)
    }

    private var metadataPolicySection: some View {
        let policy = viewModel.settings.currentMetadataPolicy
        let isCustom = viewModel.settings.selectedPreset == .custom

        return VStack(alignment: .leading, spacing: VibeCheckTheme.Spacing.xs) {
            Picker("Metadata", selection: Binding(
                get: { policy.mode },
                set: { newMode in
                    var updated = policy
                    updated.mode = newMode
                    if newMode == .stripAll {
                        updated = .stripAll
                    } else if newMode == .keepAll {
                        updated = .keepAll
                    }
                    viewModel.settings.setMetadataPolicy(updated)
                }
            )) {
                Text("Strip All").tag(MetadataPolicy.Mode.stripAll)
                Text("Keep All").tag(MetadataPolicy.Mode.keepAll)
                Text("Selective").tag(MetadataPolicy.Mode.selective)
            }
            .pickerStyle(.segmented)
            .disabled(!isCustom)

            if policy.mode == .selective {
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Keep Copyright", isOn: Binding(
                        get: { policy.keepCopyright },
                        set: { val in
                            var updated = policy
                            updated.keepCopyright = val
                            viewModel.settings.setMetadataPolicy(updated)
                        }
                    ))
                    Toggle("Keep Author", isOn: Binding(
                        get: { policy.keepAuthor },
                        set: { val in
                            var updated = policy
                            updated.keepAuthor = val
                            viewModel.settings.setMetadataPolicy(updated)
                        }
                    ))
                    Toggle("Strip GPS / Location", isOn: Binding(
                        get: { policy.stripGPS },
                        set: { val in
                            var updated = policy
                            updated.stripGPS = val
                            viewModel.settings.setMetadataPolicy(updated)
                        }
                    ))
                    Toggle("Strip Camera Info (EXIF)", isOn: Binding(
                        get: { policy.stripCameraInfo },
                        set: { val in
                            var updated = policy
                            updated.stripCameraInfo = val
                            viewModel.settings.setMetadataPolicy(updated)
                        }
                    ))
                }
                .font(VibeCheckTheme.Typography.caption)
                .disabled(!isCustom)
                .padding(.leading, VibeCheckTheme.Spacing.sm)
            }

            VibeHintText(text: "Controls which metadata is preserved in optimized images.")
        }
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
