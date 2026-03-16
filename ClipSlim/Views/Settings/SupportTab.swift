import SwiftUI
import StoreKit

struct SupportTab: View {

    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        VibeSettingsPage {
            VibeSettingsCard(title: "Tip Jar", icon: "heart.fill") {
                VibeHintText(text: "ClipSlim is free forever. Tips are optional and deeply appreciated.")

                tipContent
            }

            VibeSettingsCard(title: "About This App", icon: "info.circle") {
                VibeHintText(text: "ClipSlim is built and maintained by AppyAccidents. Everything runs locally on your Mac, no data leaves your device.")
                VibeHintText(text: "Distributed via appyaccidents.com")
            }
        }
    }

    @ViewBuilder
    private var tipContent: some View {
        let store = viewModel.tipStore

        if store.isLoading {
            HStack {
                Spacer()
                ProgressView()
                    .scaleEffect(0.8)
                Text("Loading tips...")
                    .font(VibeCheckTheme.Typography.caption)
                    .foregroundColor(VibeCheckTheme.Colors.textSecondary)
                Spacer()
            }
            .padding(.vertical, VibeCheckTheme.Spacing.sm)
        } else if store.purchaseState == .success {
            HStack {
                Spacer()
                VStack(spacing: VibeCheckTheme.Spacing.xs) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "FB8A10"))
                    Text("Thank you!")
                        .font(VibeCheckTheme.Typography.headline)
                        .foregroundColor(VibeCheckTheme.Colors.textPrimary)
                }
                Spacer()
            }
            .padding(.vertical, VibeCheckTheme.Spacing.md)
        } else {
            if case .failed(let message) = store.purchaseState {
                HStack(spacing: VibeCheckTheme.Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(VibeCheckTheme.Colors.error)
                    Text(message)
                        .font(VibeCheckTheme.Typography.caption)
                        .foregroundColor(VibeCheckTheme.Colors.error)
                        .lineLimit(2)
                }
                .padding(.bottom, VibeCheckTheme.Spacing.xs)
            }

            if store.tips.isEmpty {
                VibeHintText(text: "Tips unavailable right now. Check back later.")
            } else {
                HStack(spacing: VibeCheckTheme.Spacing.sm) {
                    ForEach(store.tips, id: \.id) { product in
                        VibeButton(
                            "\(product.displayName)\n\(product.displayPrice)",
                            style: .donation
                        ) {
                            Task { await store.purchase(product) }
                        }
                        .disabled(store.purchaseState == .purchasing)
                        .frame(maxWidth: .infinity)
                    }
                }

                if store.purchaseState == .purchasing {
                    HStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Processing...")
                            .font(VibeCheckTheme.Typography.caption)
                            .foregroundColor(VibeCheckTheme.Colors.textSecondary)
                        Spacer()
                    }
                    .padding(.top, VibeCheckTheme.Spacing.xs)
                }
            }
        }
    }
}
