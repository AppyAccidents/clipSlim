import SwiftUI
import AppKit

@MainActor
@Observable
final class QuickCropPanelService {

    private var panel: NSPanel?
    var isVisible = false

    var cropShape: CropShape = .square
    var cropSize: Int = 512

    var onApply: ((CropShape, Int) -> Void)?

    private let minSize = 16
    private let maxSize = 8192

    struct Preset: Identifiable {
        let id = UUID()
        let label: String
        let size: Int
    }

    let presets: [Preset] = [
        Preset(label: "256", size: 256),
        Preset(label: "512", size: 512),
        Preset(label: "1024", size: 1024),
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
        let size = max(minSize, min(maxSize, cropSize))
        onApply?(cropShape, size)
        dismiss()
    }

    func selectPreset(_ preset: Preset) {
        cropSize = preset.size
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

        let rootView = QuickCropContentView()
            .environment(self)

        let hosting = NSHostingView(rootView: rootView)
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 260),
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

private struct QuickCropContentView: View {
    @Environment(QuickCropPanelService.self) private var service

    private let accentOrange = VibeCheckTheme.Colors.neonOrange

    var body: some View {
        VStack(alignment: .leading, spacing: VibeCheckTheme.Spacing.md) {
            // Header
            HStack {
                Image(systemName: "crop")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(VibeCheckTheme.Colors.neonCyan)
                Text("Quick Crop")
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

            // Shape picker
            VStack(alignment: .leading, spacing: VibeCheckTheme.Spacing.xs) {
                Text("SHAPE")
                    .font(VibeCheckTheme.Typography.caption)
                    .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                    .tracking(1)

                Picker("Shape", selection: Binding(
                    get: { service.cropShape },
                    set: { service.cropShape = $0 }
                )) {
                    Text("Square").tag(CropShape.square)
                    Text("Circle").tag(CropShape.circle)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
            }

            // Size input
            HStack(spacing: VibeCheckTheme.Spacing.sm) {
                Text("Size")
                    .font(VibeCheckTheme.Typography.caption)
                    .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                TextField("", value: Binding(
                    get: { service.cropSize },
                    set: { service.cropSize = $0 }
                ), format: .number)
                    .font(VibeCheckTheme.Typography.monospacedBold)
                    .foregroundColor(VibeCheckTheme.Colors.neonCyan)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                Text("px")
                    .font(VibeCheckTheme.Typography.caption)
                    .foregroundColor(VibeCheckTheme.Colors.textTertiary)
            }

            // Presets
            HStack(spacing: VibeCheckTheme.Spacing.xs) {
                ForEach(service.presets) { preset in
                    let isSelected = service.cropSize == preset.size
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
                Text("Apply Crop")
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
        .frame(width: 300)
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
}
