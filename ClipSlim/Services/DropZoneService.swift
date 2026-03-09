import Foundation
import AppKit
import SwiftUI

struct DropItem: Identifiable {
    let id = UUID()
    let fileName: String
    let originalSize: Int
    var state: State

    enum State {
        case pending
        case processing
        case completed(savedBytes: Int, savingsPercent: Double)
        case failed(String)
    }
}

@MainActor
@Observable
final class DropZoneService {
    private(set) var isVisible = false
    var dropItems: [DropItem] = []
    var isProcessing = false
    var totalSaved: Int = 0

    var onFilesDropped: (([URL]) -> Void)?

    private var panel: NSPanel?
    private var closeObserver: NSObjectProtocol?

    func toggle() {
        if isVisible { hide() } else { show() }
    }

    func show() {
        ensurePanel()
        positionPanel()
        panel?.orderFrontRegardless()
        isVisible = true
    }

    func hide() {
        panel?.orderOut(nil)
        isVisible = false
    }

    func shutdown() {
        if let o = closeObserver {
            NotificationCenter.default.removeObserver(o)
            closeObserver = nil
        }
        panel?.orderOut(nil)
        panel?.contentView = nil
        panel = nil
        isVisible = false
        dropItems.removeAll()
        totalSaved = 0
        onFilesDropped = nil
    }

    func addPendingItem(fileName: String, originalSize: Int) -> UUID {
        let item = DropItem(fileName: fileName, originalSize: originalSize, state: .pending)
        dropItems.insert(item, at: 0)
        if dropItems.count > 100 { dropItems = Array(dropItems.prefix(100)) }
        return item.id
    }

    func updateItem(id: UUID, state: DropItem.State) {
        if let index = dropItems.firstIndex(where: { $0.id == id }) {
            dropItems[index].state = state
            if case .completed(let savedBytes, _) = state {
                totalSaved += savedBytes
            }
        }
    }

    // MARK: - Private

    private func ensurePanel() {
        if panel != nil { return }

        let rootView = DropZoneView()
            .environment(self)

        let hosting = NSHostingView(rootView: rootView)
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
            styleMask: [.nonactivatingPanel, .titled, .closable, .resizable, .fullSizeContentView],
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
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovableByWindowBackground = true
        panel.minSize = NSSize(width: 320, height: 400)
        panel.contentView = hosting
        self.panel = panel

        // Track close button
        closeObserver = NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: panel, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.isVisible = false
            }
        }
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
