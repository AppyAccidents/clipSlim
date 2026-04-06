import Foundation
import Carbon.HIToolbox

enum ShortcutAction: String, CaseIterable, Codable, Identifiable {
    case copyOptimized
    case copyOriginal
    case toggleDropZone
    case quickResize
    case quickCrop
    case pasteAndOptimize
    case clipboardToGIF

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .copyOptimized: return "Copy Last Optimized"
        case .copyOriginal: return "Copy Last Original"
        case .toggleDropZone: return "Toggle Drop Zone"
        case .quickResize: return "Quick Resize"
        case .quickCrop: return "Quick Crop"
        case .pasteAndOptimize: return "Paste & Optimize"
        case .clipboardToGIF: return "Clipboard to GIF"
        }
    }

    var iconName: String {
        switch self {
        case .copyOptimized: return "doc.on.clipboard"
        case .copyOriginal: return "arrow.uturn.backward"
        case .toggleDropZone: return "square.dashed"
        case .quickResize: return "arrow.up.left.and.arrow.down.right"
        case .quickCrop: return "crop"
        case .pasteAndOptimize: return "clipboard"
        case .clipboardToGIF: return "photo.on.rectangle.angled"
        }
    }

    /// Unique Carbon event hot key ID (1-7). Existing IDs 1 and 2 are preserved.
    var hotKeyID: UInt32 {
        switch self {
        case .copyOptimized: return 1
        case .copyOriginal: return 2
        case .toggleDropZone: return 3
        case .quickResize: return 4
        case .quickCrop: return 5
        case .pasteAndOptimize: return 6
        case .clipboardToGIF: return 7
        }
    }

    /// Unique 4-char Carbon signature for each hotkey.
    var hotKeySignature: OSType {
        switch self {
        case .copyOptimized: return OSType(0x434C5031) // CLP1
        case .copyOriginal: return OSType(0x434C5032) // CLP2
        case .toggleDropZone: return OSType(0x434C5033) // CLP3
        case .quickResize: return OSType(0x434C5034) // CLP4
        case .quickCrop: return OSType(0x434C5035) // CLP5
        case .pasteAndOptimize: return OSType(0x434C5036) // CLP6
        case .clipboardToGIF: return OSType(0x434C5037) // CLP7
        }
    }

    var defaultBinding: ShortcutBinding {
        switch self {
        case .copyOptimized:
            return ShortcutBinding(keyCode: UInt32(kVK_ANSI_1), modifiers: UInt32(optionKey))
        case .copyOriginal:
            return ShortcutBinding(keyCode: UInt32(kVK_ANSI_2), modifiers: UInt32(optionKey))
        case .toggleDropZone:
            return ShortcutBinding(keyCode: UInt32(kVK_ANSI_D), modifiers: UInt32(optionKey | shiftKey))
        case .quickResize:
            return ShortcutBinding(keyCode: UInt32(kVK_ANSI_R), modifiers: UInt32(optionKey | shiftKey))
        case .quickCrop:
            return ShortcutBinding(keyCode: UInt32(kVK_ANSI_C), modifiers: UInt32(optionKey | shiftKey))
        case .pasteAndOptimize:
            return ShortcutBinding(keyCode: UInt32(kVK_ANSI_V), modifiers: UInt32(optionKey | shiftKey))
        case .clipboardToGIF:
            return ShortcutBinding(keyCode: UInt32(kVK_ANSI_G), modifiers: UInt32(optionKey | shiftKey))
        }
    }
}

struct ShortcutBinding: Codable, Equatable {
    let keyCode: UInt32
    let modifiers: UInt32

    /// Human-readable label like "Opt+Shift+D"
    var displayString: String {
        var parts: [String] = []
        if modifiers & UInt32(controlKey) != 0 { parts.append("Ctrl") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("Opt") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("Shift") }
        if modifiers & UInt32(cmdKey) != 0 { parts.append("Cmd") }
        parts.append(Self.keyCodeToString(keyCode))
        return parts.joined(separator: "+")
    }

    private static func keyCodeToString(_ keyCode: UInt32) -> String {
        let mapping: [UInt32: String] = [
            UInt32(kVK_ANSI_A): "A", UInt32(kVK_ANSI_B): "B", UInt32(kVK_ANSI_C): "C",
            UInt32(kVK_ANSI_D): "D", UInt32(kVK_ANSI_E): "E", UInt32(kVK_ANSI_F): "F",
            UInt32(kVK_ANSI_G): "G", UInt32(kVK_ANSI_H): "H", UInt32(kVK_ANSI_I): "I",
            UInt32(kVK_ANSI_J): "J", UInt32(kVK_ANSI_K): "K", UInt32(kVK_ANSI_L): "L",
            UInt32(kVK_ANSI_M): "M", UInt32(kVK_ANSI_N): "N", UInt32(kVK_ANSI_O): "O",
            UInt32(kVK_ANSI_P): "P", UInt32(kVK_ANSI_Q): "Q", UInt32(kVK_ANSI_R): "R",
            UInt32(kVK_ANSI_S): "S", UInt32(kVK_ANSI_T): "T", UInt32(kVK_ANSI_U): "U",
            UInt32(kVK_ANSI_V): "V", UInt32(kVK_ANSI_W): "W", UInt32(kVK_ANSI_X): "X",
            UInt32(kVK_ANSI_Y): "Y", UInt32(kVK_ANSI_Z): "Z",
            UInt32(kVK_ANSI_0): "0", UInt32(kVK_ANSI_1): "1", UInt32(kVK_ANSI_2): "2",
            UInt32(kVK_ANSI_3): "3", UInt32(kVK_ANSI_4): "4", UInt32(kVK_ANSI_5): "5",
            UInt32(kVK_ANSI_6): "6", UInt32(kVK_ANSI_7): "7", UInt32(kVK_ANSI_8): "8",
            UInt32(kVK_ANSI_9): "9",
            UInt32(kVK_Space): "Space", UInt32(kVK_Return): "Return",
            UInt32(kVK_Tab): "Tab", UInt32(kVK_Escape): "Esc",
            UInt32(kVK_F1): "F1", UInt32(kVK_F2): "F2", UInt32(kVK_F3): "F3",
            UInt32(kVK_F4): "F4", UInt32(kVK_F5): "F5", UInt32(kVK_F6): "F6",
            UInt32(kVK_F7): "F7", UInt32(kVK_F8): "F8", UInt32(kVK_F9): "F9",
            UInt32(kVK_F10): "F10", UInt32(kVK_F11): "F11", UInt32(kVK_F12): "F12",
        ]
        return mapping[keyCode] ?? "Key\(keyCode)"
    }
}

/// Stores all 7 shortcut bindings as a Codable dictionary, persisted via UserDefaults.
struct ShortcutBindingsStore: Codable {
    var bindings: [String: ShortcutBinding]

    init() {
        bindings = [:]
        for action in ShortcutAction.allCases {
            bindings[action.rawValue] = action.defaultBinding
        }
    }

    func binding(for action: ShortcutAction) -> ShortcutBinding {
        bindings[action.rawValue] ?? action.defaultBinding
    }

    mutating func setBinding(_ binding: ShortcutBinding, for action: ShortcutAction) {
        bindings[action.rawValue] = binding
    }

    /// Returns actions that share the same keyCode+modifiers as the given binding, excluding the given action.
    func conflicts(for binding: ShortcutBinding, excluding action: ShortcutAction) -> [ShortcutAction] {
        ShortcutAction.allCases.filter { other in
            other != action && self.binding(for: other) == binding
        }
    }
}
