import Foundation
import Carbon.HIToolbox

@MainActor
final class HotkeyCoordinator {

    private var hotKeyRefs: [ShortcutAction: EventHotKeyRef] = [:]
    private var hasRegistered = false

    var onAction: ((ShortcutAction) -> Void)?

    // Legacy callbacks — kept for backward compat until AppViewModel is updated in Task 6
    var onCopyOptimized: (() -> Void)?
    var onCopyOriginal: (() -> Void)?

    private let log = Logger.shared

    func register(bindings: ShortcutBindingsStore) {
        unregister()
        hasRegistered = true

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData -> OSStatus in
                guard let event, let userData else { return OSStatus(eventNotHandledErr) }
                var hotKeyID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                let coordinator = Unmanaged<HotkeyCoordinator>.fromOpaque(userData).takeUnretainedValue()

                DispatchQueue.main.async {
                    if let action = ShortcutAction.allCases.first(where: { $0.hotKeyID == hotKeyID.id }) {
                        coordinator.onAction?(action)
                        // Legacy callback bridge
                        switch action {
                        case .copyOptimized: coordinator.onCopyOptimized?()
                        case .copyOriginal: coordinator.onCopyOriginal?()
                        default: break
                        }
                    }
                }
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            nil
        )

        for action in ShortcutAction.allCases {
            let binding = bindings.binding(for: action)
            let hotKeyID = EventHotKeyID(signature: action.hotKeySignature, id: action.hotKeyID)
            var ref: EventHotKeyRef?
            let status = RegisterEventHotKey(
                binding.keyCode,
                binding.modifiers,
                hotKeyID,
                GetApplicationEventTarget(),
                0,
                &ref
            )
            if status == noErr, let ref {
                hotKeyRefs[action] = ref
            } else {
                log.error("Failed to register hotkey for \(action.displayName): status \(status)")
            }
        }

        let registered = hotKeyRefs.keys.map(\.displayName).joined(separator: ", ")
        log.app("Global hotkeys registered: \(registered)")
    }

    /// Legacy register method — bridges to new system using default bindings.
    func register(viewModelPtr: UnsafeMutableRawPointer) {
        register(bindings: ShortcutBindingsStore())
    }

    func unregister() {
        for (_, ref) in hotKeyRefs {
            UnregisterEventHotKey(ref)
        }
        hotKeyRefs.removeAll()
        hasRegistered = false
    }

    /// Re-register a single action with a new binding without tearing down the entire set.
    func updateBinding(_ binding: ShortcutBinding, for action: ShortcutAction) {
        // Unregister old
        if let oldRef = hotKeyRefs.removeValue(forKey: action) {
            UnregisterEventHotKey(oldRef)
        }

        // Register new
        let hotKeyID = EventHotKeyID(signature: action.hotKeySignature, id: action.hotKeyID)
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            binding.keyCode,
            binding.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        if status == noErr, let ref {
            hotKeyRefs[action] = ref
            log.app("Updated hotkey for \(action.displayName): \(binding.displayString)")
        } else {
            log.error("Failed to update hotkey for \(action.displayName): status \(status)")
        }
    }
}
