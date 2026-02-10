import SwiftUI
import StoreKit

struct SupportTab: View {
    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        VibeSettingsPage {
            VibeSettingsCard(title: "Buy me a coffee", icon: "cup.and.saucer") {
                VibeHintText(text: "ClipSlim stays fully functional without purchases. Tips are optional.")

                if viewModel.iapService.isLoading {
                    ProgressView()
                } else if viewModel.iapService.products.isEmpty {
                    Text(viewModel.iapService.statusMessage)
                        .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                } else {
                    VStack(spacing: VibeCheckTheme.Spacing.sm) {
                        ForEach(viewModel.iapService.products, id: \.id) { product in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(product.displayName)
                                        .font(VibeCheckTheme.Typography.body)
                                        .foregroundColor(VibeCheckTheme.Colors.textPrimary)
                                    Text(product.description)
                                        .font(VibeCheckTheme.Typography.caption)
                                        .foregroundColor(VibeCheckTheme.Colors.textSecondary)
                                }
                                Spacer()
                                Button(product.displayPrice) {
                                    Task {
                                        await viewModel.iapService.buy(product)
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding(VibeCheckTheme.Spacing.sm)
                            .background(VibeCheckTheme.Colors.backgroundCard)
                            .cornerRadius(VibeCheckTheme.CornerRadius.sm)
                        }
                    }
                }

                HStack {
                    Button("Refresh purchases") {
                        Task {
                            await viewModel.iapService.refresh()
                        }
                    }
                    .buttonStyle(.bordered)

                    if viewModel.iapService.didThankUser {
                        Text("Thank you for supporting ClipSlim")
                            .font(VibeCheckTheme.Typography.caption)
                            .foregroundColor(VibeCheckTheme.Colors.success)
                    }
                }

                if !viewModel.iapService.statusMessage.isEmpty {
                    Text(viewModel.iapService.statusMessage)
                        .font(VibeCheckTheme.Typography.caption)
                        .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                }
            }
        }
        .task {
            if viewModel.iapService.products.isEmpty && !viewModel.iapService.isLoading {
                await viewModel.iapService.loadProducts()
            }
        }
    }
}
