import SwiftUI

struct FolderRulesSection: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var rules: [FolderRule] = []

    var body: some View {
        VibeSettingsCard(title: "Folder Rules", icon: "list.bullet.rectangle") {
            VibeHintText(text: "Rules apply to folder-watched files. First matching rule wins.")

            if rules.isEmpty {
                Text("No rules configured")
                    .font(VibeCheckTheme.Typography.caption)
                    .foregroundColor(VibeCheckTheme.Colors.textTertiary)
            } else {
                ForEach(rules) { rule in
                    HStack {
                        Toggle("", isOn: Binding(
                            get: { rule.isEnabled },
                            set: { newValue in
                                if let idx = rules.firstIndex(where: { $0.id == rule.id }) {
                                    rules[idx].isEnabled = newValue
                                    saveRules()
                                }
                            }
                        ))
                        .labelsHidden()
                        .frame(width: 30)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(rule.condition.displayName)
                                .font(VibeCheckTheme.Typography.caption)
                            Text(rule.action.displayName)
                                .font(VibeCheckTheme.Typography.caption)
                                .foregroundColor(VibeCheckTheme.Colors.neonCyan)
                        }
                        Spacer()
                        Button {
                            rules.removeAll { $0.id == rule.id }
                            saveRules()
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 10))
                                .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Button("Add Rule") {
                let rule = FolderRule(
                    condition: .fileSizeGreaterThan(bytes: 1_000_000),
                    action: .compressAggressive
                )
                rules.append(rule)
                saveRules()
            }
            .buttonStyle(.bordered)
        }
        .onAppear { loadRules() }
    }

    private func loadRules() {
        let data = viewModel.settings.folderRulesData
        guard let jsonData = data.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([FolderRule].self, from: jsonData) else {
            rules = []
            return
        }
        rules = decoded
    }

    private func saveRules() {
        guard let data = try? JSONEncoder().encode(rules),
              let json = String(data: data, encoding: .utf8) else { return }
        viewModel.settings.folderRulesData = json
    }
}
