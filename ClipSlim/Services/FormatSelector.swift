import Foundation

/// F2: Intelligent format selection based on content classification
final class FormatSelector: Sendable {

    static let shared = FormatSelector()

    private init() {}

    struct FormatSelectorConfig: Sendable {
        let smartFormatEnabled: Bool
        let webpPreferred: Bool
        let avifPreferred: Bool

        init(smartFormatEnabled: Bool = false, webpPreferred: Bool = false, avifPreferred: Bool = false) {
            self.smartFormatEnabled = smartFormatEnabled
            self.webpPreferred = webpPreferred
            self.avifPreferred = avifPreferred
        }

        init(from settings: AppSettings) {
            self.smartFormatEnabled = settings.smartFormatEnabled
            self.webpPreferred = settings.webpPreferred
            self.avifPreferred = settings.avifPreferred
        }
    }

    func recommendFormat(
        classification: ImageClassifier.ImageContentType,
        hasAlpha: Bool,
        config: FormatSelectorConfig
    ) -> ImageFormat {
        guard config.smartFormatEnabled else {
            return .jpeg // Defer to existing logic
        }

        switch classification {
        case .screenshot, .uiElement:
            return .png

        case .photo:
            if hasAlpha {
                return .png
            }
            if config.avifPreferred {
                return .avif
            }
            if config.webpPreferred {
                return .webp
            }
            return .jpeg

        case .mixed:
            if hasAlpha {
                return .png
            }
            if config.avifPreferred {
                return .avif
            }
            if config.webpPreferred {
                return .webp
            }
            return .jpeg
        }
    }
}
