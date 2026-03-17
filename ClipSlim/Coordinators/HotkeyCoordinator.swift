import Foundation
import Carbon.HIToolbox

@MainActor
final class HotkeyCoordinator {

    private var hotKeyRef1: EventHotKeyRef?
    private var hotKeyRef2: EventHotKeyRef?
    private var hasRegistered = false

    var onCopyOptimized: (() -> Void)?
    var onCopyOriginal: (() -> Void)?

    private let log = Logger.shared

    func register(viewModelPtr: UnsafeMutableRawPointer) {
        guard !hasRegistered else { return }
        hasRegistered = true

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        InstallEventHandler(GetApplicationEventTarget(), { _, event, userData -> OSStatus in
            guard let event, let userData else { return OSStatus(eventNotHandledErr) }
            var hotKeyID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)

            let coordinator = Unmanaged<HotkeyCoordinator>.fromOpaque(userData).takeUnretainedValue()

            DispatchQueue.main.async {
                switch hotKeyID.id {
                case 1:
                    coordinator.onCopyOptimized?()
                case 2:
                    coordinator.onCopyOriginal?()
                default:
                    break
                }
            }
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), nil)

        let hotKeyID1 = EventHotKeyID(signature: OSType(0x434C5031), id: 1)
        RegisterEventHotKey(UInt32(kVK_ANSI_1), UInt32(optionKey), hotKeyID1, GetApplicationEventTarget(), 0, &hotKeyRef1)

        let hotKeyID2 = EventHotKeyID(signature: OSType(0x434C5032), id: 2)
        RegisterEventHotKey(UInt32(kVK_ANSI_2), UInt32(optionKey), hotKeyID2, GetApplicationEventTarget(), 0, &hotKeyRef2)

        log.app("Global hotkeys registered: Option+1 (optimized), Option+2 (original)")
    }

    func unregister() {
        if let hotKeyRef1 {
            UnregisterEventHotKey(hotKeyRef1)
            self.hotKeyRef1 = nil
        }
        if let hotKeyRef2 {
            UnregisterEventHotKey(hotKeyRef2)
            self.hotKeyRef2 = nil
        }
        hasRegistered = false
    }
}
