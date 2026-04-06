import SwiftUI
import AppKit

@MainActor
@Observable
final class QuickResizePanelService {

    private var panel: NSPanel?
    var isVisible = false

    var targetWidth: Int = 1024
    var targetHeight: Int = 1024
    var lockAspectRatio: Bool = true

    var onApply: ((Int, Int) -> Void)?

    private let minDimension = 16
    private let maxDimension = 8192

    struct Preset: Identifiable {
        let id = UUID()
        let label: String
        let width: Int
        let height: Int
    }

    let presets: [Preset] = [
        Preset(label: "512x512", width: 512, height: 512),
        Preset(label: "1024x1024", width: 1024, height: 1024),
        Preset(label: "1920x1080", width: 1920, height: 1080),
    ]

    func show() {
        ensurePanel()
        positionPanel()
        panel?.orderFrontRegardless()
        isVisible = true
    }

    func dismiss() {
        panel?.orderOut(nil)
        isVisible = false
    }

    func apply() {
        let w = max(minDimension, min(maxDimension, targetWidth))
        let h = max(minDimension, min(maxDimension, targetHeight))
        onApply?(w, h)
        dismiss()
    }

    func selectPreset(_ preset: Preset) {
        targetWidth = preset.width
        targetHeight = preset.height
    }

    func clampDimensions() {
        targetWidth = max(minDimension, min(maxDimension, targetWidth))
        targetHeight = max(minDimension, min(maxDimension, targetHeight))
    }

    func shutdown() {
        panel?.orderOut(nil)
        panel?.contentView = nil
        panel = nil
        isVisible = false
        onApply = nil
    }

    private func ensurePanel() {
        if panel != nil { return }

        let rootView = QuickResizeContentView()
            .environment(self)

        let hosting = NSHostingView(rootView: rootView)
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 280),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hasShadow = true
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hidesOnDeactivate = false
        panel.contentView = hosting
        self.panel = panel
    }

    private func positionPanel() {
        guard let panel else { return }
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(mouseLocation) } ?? NSScreen.main ?? NSScreen.screens.first
        guard let screen else { return }

        let visible = screen.visibleFrame
        let x = visible.midX - panel.frame.width / 2
        let y = visible.midY - panel.frame.height / 2
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}

private struct QuickResizeContentView: View {
    @Environment(QuickResizePanelService.self) private var service

    private let accentOrange = VibeCheckTheme.Colors.neonOrange

    var body: some View {
        VStack(alignment: .leading, spacing: VibeCheckTheme.Spacing.md) {
            // Header
            HStack {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(VibeCheckTheme.Colors.neonCyan)
                Text("Quick Resize")
                    .font(VibeCheckTheme.Typography.headline)
                    .foregroundColor(VibeCheckTheme.Colors.textPrimary)
                Spacer()
                Button {
                    service.dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                        .padding(6)
                        .background(VibeCheckTheme.Colors.surface)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            // Dimension inputs
            HStack(spacing: VibeCheckTheme.Spacing.sm) {
                dimensionField("W", value: Binding(
                    get: { service.targetWidth },
                    set: { service.targetWidth = $0 }
                ))

                Button {
                    service.lockAspectRatio.toggle()
                } label: {
                    Image(systemName: service.lockAspectRatio ? "lock.fill" : "lock.open")
                        .font(.system(size: 12))
                        .foregroundColor(service.lockAspectRatio ? VibeCheckTheme.Colors.neonCyan : VibeCheckTheme.Colors.textTertiary)
                }
                .buttonStyle(.plain)
                .help("Lock aspect ratio")

                dimensionField("H", value: Binding(
                    get: { service.targetHeight },
                    set: { service.targetHeight = $0 }
                ))
            }

            // Presets
            HStack(spacing: VibeCheckTheme.Spacing.xs) {
                ForEach(service.presets) { preset in
                    let isSelected = service.targetWidth == preset.width && service.targetHeight == preset.height
                    Button {
                        service.selectPreset(preset)
                    } label: {
                        Text(preset.label)
                            .font(VibeCheckTheme.Typography.caption)
                            .foregroundColor(isSelected ? .white : VibeCheckTheme.Colors.textSecondary)
                            .padding(.horizontal, VibeCheckTheme.Spacing.sm)
                            .padding(.vertical, VibeCheckTheme.Spacing.xs)
                            .background(isSelected ? accentOrange : VibeCheckTheme.Colors.surface)
                            .cornerRadius(VibeCheckTheme.CornerRadius.sm)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }

            // Apply button
            Button {
                service.apply()
            } label: {
                Text("Apply Resize")
                    .font(VibeCheckTheme.Typography.body)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, VibeCheckTheme.Spacing.sm)
                    .background(accentOrange)
                    .cornerRadius(VibeCheckTheme.CornerRadius.sm)
            }
            .buttonStyle(.plain)
        }
        .padding(VibeCheckTheme.Spacing.xl)
        .frame(width: 320)
        .background(
            ZStack {
                Color(hex: "111116").opacity(0.82)
                Rectangle().fill(.ultraThinMaterial)
            }
        )
        .cornerRadius(VibeCheckTheme.CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: VibeCheckTheme.CornerRadius.lg)
                .stroke(
                    LinearGradient(
                        colors: [accentOrange.opacity(0.45), accentOrange.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.55), radius: 24, x: 0, y: 8)
        .shadow(color: accentOrange.opacity(0.08), radius: 12, x: 0, y: 0)
        .onKeyPress(.escape) {
            service.dismiss()
            return .handled
        }
    }

    private func dimensionField(_ label: String, value: Binding<Int>) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(VibeCheckTheme.Typography.caption)
                .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                .frame(width: 16)
            TextField("", value: value, format: .number)
                .font(VibeCheckTheme.Typography.monospacedBold)
                .foregroundColor(VibeCheckTheme.Colors.neonCyan)
                .textFieldStyle(.roundedBorder)
                .frame(width: 80)
                .onSubmit { service.clampDimensions() }
        }
    }
}
