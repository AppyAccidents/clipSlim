import XCTest
@testable import ClipSlim

final class SocialMediaPresetTests: XCTestCase {

    func testAllPresetsCount() {
        XCTAssertEqual(SocialMediaPreset.allCases.count, 12)
    }

    func testAllPresetsHaveNonZeroDimensions() {
        for preset in SocialMediaPreset.allCases {
            XCTAssertGreaterThan(preset.width, 0, "\(preset) width should be > 0")
            XCTAssertGreaterThan(preset.height, 0, "\(preset) height should be > 0")
        }
    }

    func testAllPresetsHaveNonEmptyDisplayName() {
        for preset in SocialMediaPreset.allCases {
            XCTAssertFalse(preset.displayName.isEmpty, "\(preset) should have a display name")
        }
    }

    func testAllPresetsHaveNonEmptyPlatform() {
        for preset in SocialMediaPreset.allCases {
            XCTAssertFalse(preset.platform.isEmpty, "\(preset) should have a platform")
        }
    }

    func testGroupedByPlatformProducesCorrectGroups() {
        let grouped = SocialMediaPreset.grouped
        let platforms = grouped.map(\.platform)

        XCTAssertTrue(platforms.contains("Twitter/X"))
        XCTAssertTrue(platforms.contains("Instagram"))
        XCTAssertTrue(platforms.contains("LinkedIn"))
        XCTAssertTrue(platforms.contains("Facebook"))
        XCTAssertTrue(platforms.contains("YouTube"))
        XCTAssertTrue(platforms.contains("Open Graph"))
        XCTAssertTrue(platforms.contains("Favicon"))

        // Twitter/X should have 2 presets
        let twitterGroup = grouped.first { $0.platform == "Twitter/X" }
        XCTAssertEqual(twitterGroup?.presets.count, 2)

        // Instagram should have 3 presets
        let instaGroup = grouped.first { $0.platform == "Instagram" }
        XCTAssertEqual(instaGroup?.presets.count, 3)
    }

    func testDimensionLabel() {
        XCTAssertEqual(SocialMediaPreset.twitterPost.dimensionLabel, "1600x900")
        XCTAssertEqual(SocialMediaPreset.instagramSquare.dimensionLabel, "1080x1080")
        XCTAssertEqual(SocialMediaPreset.favicon.dimensionLabel, "512x512")
    }

    func testSpecificDimensions() {
        XCTAssertEqual(SocialMediaPreset.twitterPost.width, 1600)
        XCTAssertEqual(SocialMediaPreset.twitterPost.height, 900)
        XCTAssertEqual(SocialMediaPreset.instagramStory.width, 1080)
        XCTAssertEqual(SocialMediaPreset.instagramStory.height, 1920)
        XCTAssertEqual(SocialMediaPreset.linkedinCover.width, 1584)
        XCTAssertEqual(SocialMediaPreset.linkedinCover.height, 396)
    }
}
