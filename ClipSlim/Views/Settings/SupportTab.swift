import SwiftUI
import AppKit

struct SupportTab: View {

    var body: some View {
        VibeSettingsPage {
            VibeSettingsCard(title: "Support ClipSlim", icon: "cup.and.saucer") {
                VibeHintText(text: "ClipSlim is free and tiny but hungry. If it saves you time, coffee keeps the chaos alive.")

                VibeButton("Donate on Buy Me a Coffee ☕", style: .donation) {
                    if let url = URL(string: "https://buymeacoffee.com/appyaccidents") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            VibeSettingsCard(title: "About This App", icon: "info.circle") {
                VibeHintText(text: "ClipSlim is built and maintained by AppyAccidents. Everything runs locally on your Mac, no data leaves your device.")
                VibeHintText(text: "Distributed via appyaccidents.com")
                VibeHintText(text: "PDF support: Coming soon")
                VibeHintText(text: "PDF page separation/stitching: Coming soon")
            }
        }
    }
}
