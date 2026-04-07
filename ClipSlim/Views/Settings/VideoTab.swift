import SwiftUI

struct VideoTab: View {

    @Environment(AppViewModel.self) private var viewModel

    private var settings: AppSettings { viewModel.settings }

    var body: some View {
        VibeSettingsPage {
            VibeSettingsCard(title: "Video Compression", icon: "film") {
                Toggle("Enable video compression", isOn: settings.videoCompressionEnabledBinding)
                VibeHintText(text: "Compress video files from clipboard, folder watcher, and drop zone. Uses hardware-accelerated encoding on Apple Silicon.")
            }

            VibeSettingsCard(title: "Codec", icon: "cpu") {
                Picker("Codec", selection: settings.videoCodecBinding) {
                    ForEach(VideoCodec.allCases, id: \.self) { codec in
                        Text(codec.rawValue).tag(codec)
                    }
                }
                .pickerStyle(.segmented)

                VibeHintText(text: "H.265 produces smaller files but has less universal compatibility. H.264 is widely supported.")
            }
            .opacity(settings.videoCompressionEnabled ? 1.0 : 0.5)
            .disabled(!settings.videoCompressionEnabled)

            VibeSettingsCard(title: "Quality", icon: "slider.horizontal.3") {
                HStack {
                    Text("\(Int(settings.videoQuality * 100))%")
                        .font(VibeCheckTheme.Typography.monospacedFont)
                        .frame(width: 50, alignment: .leading)

                    Slider(value: settings.videoQualityBinding, in: 0.4...1.0, step: 0.05)
                }

                HStack(spacing: VibeCheckTheme.Spacing.md) {
                    qualityPresetButton("Low", quality: 0.4)
                    qualityPresetButton("Medium", quality: 0.65)
                    qualityPresetButton("High", quality: 0.85)
                }

                VibeHintText(text: "Lower quality = smaller files. 65% is a good balance for most content.")
            }
            .opacity(settings.videoCompressionEnabled ? 1.0 : 0.5)
            .disabled(!settings.videoCompressionEnabled)

            VibeSettingsCard(title: "Max Resolution", icon: "arrow.up.left.and.arrow.down.right") {
                Picker("Resolution", selection: settings.videoMaxResolutionBinding) {
                    ForEach(VideoMaxResolution.allCases, id: \.self) { res in
                        Text(res.label).tag(res)
                    }
                }
                .pickerStyle(.segmented)

                VibeHintText(text: "Videos larger than the selected resolution will be downscaled. Videos already smaller are left unchanged.")
            }
            .opacity(settings.videoCompressionEnabled ? 1.0 : 0.5)
            .disabled(!settings.videoCompressionEnabled)

            VibeSettingsCard(title: "Metadata", icon: "tag") {
                Toggle("Strip metadata", isOn: settings.videoStripMetadataBinding)
                VibeHintText(text: "Remove location, camera, and other metadata from compressed videos.")
            }
            .opacity(settings.videoCompressionEnabled ? 1.0 : 0.5)
            .disabled(!settings.videoCompressionEnabled)

            VibeSettingsCard(title: "GIF Settings", icon: "photo.on.rectangle") {
                HStack {
                    Text("Max Colors")
                        .font(VibeCheckTheme.Typography.body)
                    Spacer()
                    HStack(spacing: VibeCheckTheme.Spacing.xs) {
                        gifColorButton(64)
                        gifColorButton(128)
                        gifColorButton(256)
                    }
                }

                HStack {
                    Text("Frame Skip")
                        .font(VibeCheckTheme.Typography.body)
                    Spacer()
                    HStack(spacing: VibeCheckTheme.Spacing.xs) {
                        frameSkipButton("None", skip: 0)
                        frameSkipButton("2x", skip: 1)
                        frameSkipButton("3x", skip: 2)
                    }
                }

                HStack {
                    Text("Video-to-GIF FPS")
                        .font(VibeCheckTheme.Typography.body)
                    Spacer()
                    HStack(spacing: VibeCheckTheme.Spacing.xs) {
                        fpsButton(5)
                        fpsButton(10)
                        fpsButton(15)
                    }
                }

                VibeHintText(text: "Fewer colors and frame skipping reduce GIF file size. Video-to-GIF is capped at 15 seconds.")
            }
        }
    }

    // MARK: - Helpers

    private func qualityPresetButton(_ label: String, quality: Double) -> some View {
        Button {
            settings.videoQuality = quality
        } label: {
            Text(label)
                .font(VibeCheckTheme.Typography.caption)
                .foregroundColor(abs(settings.videoQuality - quality) < 0.01 ? VibeCheckTheme.Colors.backgroundPrimary : VibeCheckTheme.Colors.textSecondary)
                .padding(.horizontal, VibeCheckTheme.Spacing.sm)
                .padding(.vertical, VibeCheckTheme.Spacing.xs)
                .background(abs(settings.videoQuality - quality) < 0.01 ? VibeCheckTheme.Colors.neonOrange : Color.white.opacity(0.07))
                .cornerRadius(VibeCheckTheme.CornerRadius.sm)
        }
        .buttonStyle(.plain)
    }

    private func gifColorButton(_ colors: Int) -> some View {
        Button {
            settings.gifMaxColors = colors
        } label: {
            Text("\(colors)")
                .font(VibeCheckTheme.Typography.caption)
                .foregroundColor(settings.gifMaxColors == colors ? VibeCheckTheme.Colors.backgroundPrimary : VibeCheckTheme.Colors.textSecondary)
                .padding(.horizontal, VibeCheckTheme.Spacing.sm)
                .padding(.vertical, VibeCheckTheme.Spacing.xs)
                .background(settings.gifMaxColors == colors ? VibeCheckTheme.Colors.neonOrange : Color.white.opacity(0.07))
                .cornerRadius(VibeCheckTheme.CornerRadius.sm)
        }
        .buttonStyle(.plain)
    }

    private func frameSkipButton(_ label: String, skip: Int) -> some View {
        Button {
            settings.gifFrameSkip = skip
        } label: {
            Text(label)
                .font(VibeCheckTheme.Typography.caption)
                .foregroundColor(settings.gifFrameSkip == skip ? VibeCheckTheme.Colors.backgroundPrimary : VibeCheckTheme.Colors.textSecondary)
                .padding(.horizontal, VibeCheckTheme.Spacing.sm)
                .padding(.vertical, VibeCheckTheme.Spacing.xs)
                .background(settings.gifFrameSkip == skip ? VibeCheckTheme.Colors.neonOrange : Color.white.opacity(0.07))
                .cornerRadius(VibeCheckTheme.CornerRadius.sm)
        }
        .buttonStyle(.plain)
    }

    private func fpsButton(_ fps: Int) -> some View {
        Button {
            settings.videoToGifFPS = fps
        } label: {
            Text("\(fps)")
                .font(VibeCheckTheme.Typography.caption)
                .foregroundColor(settings.videoToGifFPS == fps ? VibeCheckTheme.Colors.backgroundPrimary : VibeCheckTheme.Colors.textSecondary)
                .padding(.horizontal, VibeCheckTheme.Spacing.sm)
                .padding(.vertical, VibeCheckTheme.Spacing.xs)
                .background(settings.videoToGifFPS == fps ? VibeCheckTheme.Colors.neonOrange : Color.white.opacity(0.07))
                .cornerRadius(VibeCheckTheme.CornerRadius.sm)
        }
        .buttonStyle(.plain)
    }
}
