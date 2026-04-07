import SwiftUI
import AppKit
import Carbon.HIToolbox

struct KeyRecorderView: View {
    let action: ShortcutAction
    @Binding var binding: ShortcutBinding
    var onChanged: ((ShortcutBinding) -> Void)?

    @State private var isRecording = false

    var body: some View {
        Button {
            isRecording.toggle()
        } label: {
            HStack(spacing: 4) {
                if isRecording {
                    Text("Press keys...")
                        .font(VibeCheckTheme.Typography.caption)
                        .foregroundColor(VibeCheckTheme.Colors.neonOrange)
                } else {
                    Text(binding.displayString)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(VibeCheckTheme.Colors.textPrimary)
                }
            }
            .padding(.horizontal, VibeCheckTheme.Spacing.sm)
            .padding(.vertical, VibeCheckTheme.Spacing.xs)
            .background(
                isRecording
                    ? VibeCheckTheme.Colors.neonOrange.opacity(0.15)
                    : VibeCheckTheme.Colors.surface
            )
            .cornerRadius(VibeCheckTheme.CornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: VibeCheckTheme.CornerRadius.sm)
                    .stroke(
                        isRecording ? VibeCheckTheme.Colors.neonOrange : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .onKeyPress(phases: .down) { press in
            guard isRecording else { return .ignored }

            let modifiers = carbonModifiers(from: press.modifiers)
            // Require at least one modifier key
            guard modifiers != 0 else { return .ignored }

            let keyCode = keyCodeFromKeyEquivalent(press.key)
            guard keyCode != UInt32.max else { return .ignored }

            let newBinding = ShortcutBinding(keyCode: keyCode, modifiers: modifiers)
            binding = newBinding
            isRecording = false
            onChanged?(newBinding)
            return .handled
        }
        .onKeyPress(.escape) {
            if isRecording {
                isRecording = false
                return .handled
            }
            return .ignored
        }
    }

    private func carbonModifiers(from swiftModifiers: SwiftUI.EventModifiers) -> UInt32 {
        var result: UInt32 = 0
        if swiftModifiers.contains(.command) { result |= UInt32(cmdKey) }
        if swiftModifiers.contains(.option) { result |= UInt32(optionKey) }
        if swiftModifiers.contains(.shift) { result |= UInt32(shiftKey) }
        if swiftModifiers.contains(.control) { result |= UInt32(controlKey) }
        return result
    }

    /// Best-effort mapping from KeyEquivalent character to Carbon key code.
    private func keyCodeFromKeyEquivalent(_ key: KeyEquivalent) -> UInt32 {
        let char = String(key.character).lowercased()
        let map: [String: UInt32] = [
            "a": UInt32(kVK_ANSI_A), "b": UInt32(kVK_ANSI_B), "c": UInt32(kVK_ANSI_C),
            "d": UInt32(kVK_ANSI_D), "e": UInt32(kVK_ANSI_E), "f": UInt32(kVK_ANSI_F),
            "g": UInt32(kVK_ANSI_G), "h": UInt32(kVK_ANSI_H), "i": UInt32(kVK_ANSI_I),
            "j": UInt32(kVK_ANSI_J), "k": UInt32(kVK_ANSI_K), "l": UInt32(kVK_ANSI_L),
            "m": UInt32(kVK_ANSI_M), "n": UInt32(kVK_ANSI_N), "o": UInt32(kVK_ANSI_O),
            "p": UInt32(kVK_ANSI_P), "q": UInt32(kVK_ANSI_Q), "r": UInt32(kVK_ANSI_R),
            "s": UInt32(kVK_ANSI_S), "t": UInt32(kVK_ANSI_T), "u": UInt32(kVK_ANSI_U),
            "v": UInt32(kVK_ANSI_V), "w": UInt32(kVK_ANSI_W), "x": UInt32(kVK_ANSI_X),
            "y": UInt32(kVK_ANSI_Y), "z": UInt32(kVK_ANSI_Z),
            "0": UInt32(kVK_ANSI_0), "1": UInt32(kVK_ANSI_1), "2": UInt32(kVK_ANSI_2),
            "3": UInt32(kVK_ANSI_3), "4": UInt32(kVK_ANSI_4), "5": UInt32(kVK_ANSI_5),
            "6": UInt32(kVK_ANSI_6), "7": UInt32(kVK_ANSI_7), "8": UInt32(kVK_ANSI_8),
            "9": UInt32(kVK_ANSI_9),
        ]
        return map[char] ?? UInt32.max
    }
}
