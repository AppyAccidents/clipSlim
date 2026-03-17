import SwiftUI

/// F4: Pipeline step toggles in the Presets tab
struct PipelineSection: View {

    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        VibeSettingsCard(title: "Pipeline Steps", icon: "line.3.horizontal.decrease") {
            VibeHintText(text: "Toggle individual optimization steps. Disabled steps are skipped.")

            ForEach(PipelineStep.allCases) { step in
                let isEnabled = viewModel.settings.isPipelineStepEnabled(step)
                Toggle(isOn: Binding(
                    get: { isEnabled },
                    set: { _ in viewModel.settings.togglePipelineStep(step) }
                )) {
                    HStack(spacing: VibeCheckTheme.Spacing.sm) {
                        Image(systemName: step.icon)
                            .foregroundColor(isEnabled ? VibeCheckTheme.Colors.neonCyan : VibeCheckTheme.Colors.textTertiary)
                            .frame(width: 16)
                        Text(step.displayName)
                    }
                }
            }
        }
    }
}
