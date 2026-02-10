import SwiftUI

struct RulesTab: View {
    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        VibeSettingsPage {
            VibeSettingsCard(title: "Rules (first match wins)", icon: "line.3.horizontal.decrease.circle") {
                ScrollView {
                    VStack(spacing: 0) {
                        if viewModel.settings.rules.isEmpty {
                            Text("No rules configured")
                                .font(VibeCheckTheme.Typography.caption)
                                .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(VibeCheckTheme.Spacing.md)
                        } else {
                            ForEach(Array(viewModel.settings.rules.enumerated()), id: \.element.id) { index, rule in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Toggle(rule.name, isOn: binding(for: index, keyPath: \.enabled))
                                        Spacer()
                                        Button("Delete") {
                                            var rules = viewModel.settings.rules
                                            rules.removeAll { $0.id == rule.id }
                                            viewModel.settings.rules = rules
                                        }
                                        .buttonStyle(.borderless)
                                    }

                                    TextField("Bundle ID", text: binding(for: index, keyPath: \.frontmostBundleID))
                                        .textFieldStyle(.roundedBorder)

                                    HStack {
                                        Text("Skip")
                                        Toggle("", isOn: binding(for: index, keyPath: \.shouldSkip))
                                            .labelsHidden()
                                        Spacer()
                                        Picker("Format", selection: Binding(
                                            get: { viewModel.settings.rules[index].overrideFormatRaw },
                                            set: { value in
                                                var rules = viewModel.settings.rules
                                                rules[index].overrideFormatRaw = value
                                                viewModel.settings.rules = rules
                                            }
                                        )) {
                                            Text("No override").tag("")
                                            Text("JPEG").tag(ImageFormat.jpeg.rawValue)
                                            Text("PNG").tag(ImageFormat.png.rawValue)
                                        }
                                        .frame(width: 170)
                                    }
                                }
                                .padding(VibeCheckTheme.Spacing.md)

                                if rule.id != viewModel.settings.rules.last?.id {
                                    VibeDivider()
                                }
                            }
                        }
                    }
                }
                .frame(height: 300)
                .background(VibeCheckTheme.Colors.backgroundCard)
                .cornerRadius(VibeCheckTheme.CornerRadius.sm)

                HStack {
                    Button("Add Rule") {
                        var rules = viewModel.settings.rules
                        rules.append(OptimizationRule(name: "New Rule"))
                        viewModel.settings.rules = rules
                    }

                    Button("Template: Skip Zoom") {
                        var rules = viewModel.settings.rules
                        rules.append(OptimizationRule(name: "Skip Zoom", frontmostBundleID: "us.zoom.xos", shouldSkip: true))
                        viewModel.settings.rules = rules
                    }

                    Button("Template: PNG for alpha") {
                        var rules = viewModel.settings.rules
                        rules.append(OptimizationRule(name: "PNG for transparency", transparencyCondition: .transparent, overrideFormat: .png))
                        viewModel.settings.rules = rules
                    }
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func binding<T>(for index: Int, keyPath: WritableKeyPath<OptimizationRule, T>) -> Binding<T> {
        Binding(
            get: { viewModel.settings.rules[index][keyPath: keyPath] },
            set: { value in
                var rules = viewModel.settings.rules
                rules[index][keyPath: keyPath] = value
                viewModel.settings.rules = rules
            }
        )
    }
}
