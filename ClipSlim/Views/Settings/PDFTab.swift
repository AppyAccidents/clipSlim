import SwiftUI

struct PDFTab: View {

    @Environment(AppViewModel.self) private var viewModel

    private var settings: AppSettings { viewModel.settings }

    var body: some View {
        VibeSettingsPage {
            VibeSettingsCard(title: "PDF Compression", icon: "doc.richtext") {
                Toggle("Enable PDF compression", isOn: settings.pdfCompressionEnabledBinding)
                VibeHintText(text: "Text-based PDFs are optimized losslessly. DPI and quality settings apply to image-heavy PDFs (scans, photos).")
            }

            VibeSettingsCard(title: "Target DPI", icon: "gauge.with.dots.needle.33percent") {
                HStack {
                    Text("\(settings.pdfTargetDPI) DPI")
                        .font(VibeCheckTheme.Typography.monospacedFont)
                        .frame(width: 80, alignment: .leading)

                    Slider(
                        value: Binding(
                            get: { Double(settings.pdfTargetDPI) },
                            set: { settings.pdfTargetDPI = Int($0) }
                        ),
                        in: 72...300,
                        step: 10
                    )
                }

                HStack(spacing: VibeCheckTheme.Spacing.md) {
                    dpiPresetButton("72 (Screen)", dpi: 72)
                    dpiPresetButton("150 (Default)", dpi: 150)
                    dpiPresetButton("300 (Print)", dpi: 300)
                }

                VibeHintText(text: "Lower DPI = smaller files but reduced quality. 150 DPI is a good balance.")
            }
            .opacity(settings.pdfCompressionEnabled ? 1.0 : 0.5)
            .disabled(!settings.pdfCompressionEnabled)

            VibeSettingsCard(title: "Image Quality", icon: "slider.horizontal.3") {
                HStack {
                    Text("\(Int(settings.pdfImageQuality * 100))%")
                        .font(VibeCheckTheme.Typography.monospacedFont)
                        .frame(width: 50, alignment: .leading)

                    Slider(value: settings.pdfImageQualityBinding, in: 0.1...1.0, step: 0.05)
                }

                VibeHintText(text: "JPEG quality for rendered PDF pages. Lower = smaller files.")
            }
            .opacity(settings.pdfCompressionEnabled ? 1.0 : 0.5)
            .disabled(!settings.pdfCompressionEnabled)

            VibeSettingsCard(title: "Metadata", icon: "tag") {
                Toggle("Strip metadata", isOn: settings.pdfStripMetadataBinding)
                VibeHintText(text: "Remove author, title, and other metadata from compressed PDFs.")
            }
            .opacity(settings.pdfCompressionEnabled ? 1.0 : 0.5)
            .disabled(!settings.pdfCompressionEnabled)

            VibeSettingsCard(title: "Drop Zone", icon: "square.and.arrow.down.on.square") {
                Toggle("Show Drop Zone on launch", isOn: settings.dropZoneVisibleOnLaunchBinding)
                VibeHintText(text: "Automatically open the Drop Zone window when ClipSlim starts.")
            }
        }
    }

    // MARK: - Helpers

    private func dpiPresetButton(_ label: String, dpi: Int) -> some View {
        Button {
            settings.pdfTargetDPI = dpi
        } label: {
            Text(label)
                .font(VibeCheckTheme.Typography.caption)
                .foregroundColor(settings.pdfTargetDPI == dpi ? VibeCheckTheme.Colors.backgroundPrimary : VibeCheckTheme.Colors.textSecondary)
                .padding(.horizontal, VibeCheckTheme.Spacing.sm)
                .padding(.vertical, VibeCheckTheme.Spacing.xs)
                .background(settings.pdfTargetDPI == dpi ? VibeCheckTheme.Colors.neonCyan : Color.white.opacity(0.07))
                .cornerRadius(VibeCheckTheme.CornerRadius.sm)
        }
        .buttonStyle(.plain)
    }
}
