import SwiftUI
import AppKit

struct SupportTab: View {

    var body: some View {
        VibeSettingsPage {
            VibeSettingsCard(title: "Support ClipSlim", icon: "cup.and.saucer") {
                VibeHintText(text: "ClipSlim is free and always will be. If it saves you time, consider buying me a coffee — it means the world!")

                VibeButton("Donate on Buy Me a Coffee ☕", style: .donation) {
                    if let url = URL(string: "https://buymeacoffee.com/appyaccidents") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            VibeSettingsCard(title: "About This App", icon: "info.circle") {
                VibeHintText(text: "ClipSlim is built and maintained by AppyAccidents. All processing happens locally on your Mac — no data ever leaves your device.")
                VibeHintText(text: "Distributed via appyaccidents.com")
            }
        }
    }
}
