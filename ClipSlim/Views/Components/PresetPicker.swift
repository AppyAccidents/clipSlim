import SwiftUI

@available(*, deprecated, message: "Use PresetButtonGroup directly")
struct PresetPicker: View {
    @Binding var selectedPreset: OptimizationPreset

    var body: some View {
        PresetButtonGroup(
            selectedPreset: $selectedPreset,
            labelStyle: .compact
        )
    }
}
