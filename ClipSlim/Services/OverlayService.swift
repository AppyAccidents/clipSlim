import Foundation
import AppKit
import SwiftUI

struct OverlayItem {
    let originalData: Data
    let optimizedData: Data
    let result: OptimizationResult
    let formatOverrideSelection: ImageFormat
    let sourceAppBundleID: String
}

@MainActor
@Observable
final class OverlayService {
    private(set) var currentItem: OverlayItem?

    var onUndo: (() -> Void)?
    var onSaveAs: (() -> Void)?
    var onRemoveClipboardImage: (() -> Void)?
    var onApplyFormatOverride: ((ImageFormat) -> Void)?
    var onApplyResizeOverride: ((Int, Int) -> Void)?
    var onOpenSettings: (() -> Void)?
    var onIgnoreImage: (() -> Void)?
    var onIgnoreApp: (() -> Void)?

    private var panel: NSPanel?
    private var dismissTimer: Timer?

    private let autoDismissSeconds: TimeInterval = 5.0

    // Chosen anchor: top-right of main screen for predictable placement and no cursor tracking overhead.
    func show(item: OverlayItem) {
        currentItem = item
        ensurePanel()
        positionPanel()
        panel?.orderFrontRegardless()
        scheduleDismiss()
    }

    func dismiss() {
        dismissTimer?.invalidate()
        dismissTimer = nil
        panel?.orderOut(nil)
        currentItem = nil
    }

    func pauseDismiss() {
        dismissTimer?.invalidate()
        dismissTimer = nil
    }

    func resumeDismiss() {
        scheduleDismiss()
    }

    private func scheduleDismiss() {
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: autoDismissSeconds, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.dismiss()
            }
        }
    }

    private func ensurePanel() {
        if panel != nil { return }

        let rootView = OverlayView()
            .environment(self)

        let hosting = NSHostingView(rootView: rootView)
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 392, height: 364),
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
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }

        let visible = screen.visibleFrame
        let x = visible.maxX - panel.frame.width - 16
        let y = visible.maxY - panel.frame.height - 16
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
