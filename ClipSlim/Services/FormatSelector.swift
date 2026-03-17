import Foundation

/// F2: Intelligent format selection based on content classification
final class FormatSelector: Sendable {

    static let shared = FormatSelector()

    private init() {}

    struct FormatSelectorConfig: Sendable {
        let smartFormatEnabled: Bool
        let webpPreferred: Bool

        init(smartFormatEnabled: Bool = false, webpPreferred: Bool = false) {
            self.smartFormatEnabled = smartFormatEnabled
            self.webpPreferred = webpPreferred
        }

        init(from settings: AppSettings) {
            self.smartFormatEnabled = settings.smartFormatEnabled
            self.webpPreferred = settings.webpPreferred
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
            if config.webpPreferred {
                return .webp
            }
            return .jpeg

        case .mixed:
            if hasAlpha {
                return .png
            }
            if config.webpPreferred {
                return .webp
            }
            return .jpeg
        }
    }
}
