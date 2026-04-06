import Foundation

enum SocialMediaPreset: String, CaseIterable, Identifiable {
    case twitterPost
    case twitterHeader
    case instagramSquare
    case instagramStory
    case instagramLandscape
    case linkedinPost
    case linkedinCover
    case facebookPost
    case facebookCover
    case youtubeThumbnail
    case openGraphImage
    case favicon

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .twitterPost: return "Post"
        case .twitterHeader: return "Header"
        case .instagramSquare: return "Square"
        case .instagramStory: return "Story"
        case .instagramLandscape: return "Landscape"
        case .linkedinPost: return "Post"
        case .linkedinCover: return "Cover"
        case .facebookPost: return "Post"
        case .facebookCover: return "Cover"
        case .youtubeThumbnail: return "Thumbnail"
        case .openGraphImage: return "OG Image"
        case .favicon: return "Favicon"
        }
    }

    var platform: String {
        switch self {
        case .twitterPost, .twitterHeader: return "Twitter/X"
        case .instagramSquare, .instagramStory, .instagramLandscape: return "Instagram"
        case .linkedinPost, .linkedinCover: return "LinkedIn"
        case .facebookPost, .facebookCover: return "Facebook"
        case .youtubeThumbnail: return "YouTube"
        case .openGraphImage: return "Open Graph"
        case .favicon: return "Favicon"
        }
    }

    var width: Int {
        switch self {
        case .twitterPost: return 1600
        case .twitterHeader: return 1500
        case .instagramSquare: return 1080
        case .instagramStory: return 1080
        case .instagramLandscape: return 1080
        case .linkedinPost: return 1200
        case .linkedinCover: return 1584
        case .facebookPost: return 1200
        case .facebookCover: return 851
        case .youtubeThumbnail: return 1280
        case .openGraphImage: return 1200
        case .favicon: return 512
        }
    }

    var height: Int {
        switch self {
        case .twitterPost: return 900
        case .twitterHeader: return 500
        case .instagramSquare: return 1080
        case .instagramStory: return 1920
        case .instagramLandscape: return 566
        case .linkedinPost: return 627
        case .linkedinCover: return 396
        case .facebookPost: return 630
        case .facebookCover: return 315
        case .youtubeThumbnail: return 720
        case .openGraphImage: return 630
        case .favicon: return 512
        }
    }

    var dimensionLabel: String {
        "\(width)x\(height)"
    }

    /// Groups all presets by platform, preserving case order within each group.
    static var grouped: [(platform: String, presets: [SocialMediaPreset])] {
        var seen: [String] = []
        var groups: [String: [SocialMediaPreset]] = [:]

        for preset in allCases {
            if groups[preset.platform] == nil {
                seen.append(preset.platform)
                groups[preset.platform] = []
            }
            groups[preset.platform]?.append(preset)
        }

        return seen.map { platform in
            (platform: platform, presets: groups[platform] ?? [])
        }
    }
}
