import XCTest
@testable import ClipSlim

final class ShortcutActionTests: XCTestCase {

    func testAllActionsHaveUniqueHotKeyIDs() {
        let ids = ShortcutAction.allCases.map(\.hotKeyID)
        XCTAssertEqual(ids.count, Set(ids).count, "Duplicate hotkey IDs found")
    }

    func testAllActionsHaveUniqueSignatures() {
        let sigs = ShortcutAction.allCases.map(\.hotKeySignature)
        XCTAssertEqual(sigs.count, Set(sigs).count, "Duplicate signatures found")
    }

    func testDefaultBindingsDisplayString() {
        let binding = ShortcutAction.toggleDropZone.defaultBinding
        XCTAssertEqual(binding.displayString, "Opt+Shift+D")
    }

    func testBindingsStoreCodableRoundTrip() throws {
        var store = ShortcutBindingsStore()
        let custom = ShortcutBinding(keyCode: 0, modifiers: 0)
        store.setBinding(custom, for: .quickResize)

        let data = try JSONEncoder().encode(store)
        let decoded = try JSONDecoder().decode(ShortcutBindingsStore.self, from: data)
        XCTAssertEqual(decoded.binding(for: .quickResize), custom)
        XCTAssertEqual(decoded.binding(for: .toggleDropZone), ShortcutAction.toggleDropZone.defaultBinding)
    }

    func testConflictDetection() {
        var store = ShortcutBindingsStore()
        // Set quickResize to the same binding as toggleDropZone
        let dropZoneBinding = store.binding(for: .toggleDropZone)
        store.setBinding(dropZoneBinding, for: .quickResize)

        let conflicts = store.conflicts(for: dropZoneBinding, excluding: .toggleDropZone)
        XCTAssertTrue(conflicts.contains(.quickResize))
    }
}
