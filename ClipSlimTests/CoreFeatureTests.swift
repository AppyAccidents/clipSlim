import XCTest
@testable import ClipSlim

final class CoreFeatureTests: XCTestCase {

    func testIgnoreCacheExpiration() {
        let cache = IgnoreCache()
        let hash = "abc"
        let now = Date()

        cache.add(hash, ttl: 1, now: now)
        XCTAssertTrue(cache.contains(hash, now: now))

        let future = now.addingTimeInterval(2)
        XCTAssertFalse(cache.contains(hash, now: future))
    }

    func testAdaptivePollingIntervals() {
        XCTAssertEqual(ClipboardWatcher.interval(forIdleDuration: 0), 0.5, accuracy: 0.001)
        XCTAssertEqual(ClipboardWatcher.interval(forIdleDuration: 31), 1.5, accuracy: 0.001)
        XCTAssertEqual(ClipboardWatcher.interval(forIdleDuration: 121), 3.0, accuracy: 0.001)
    }

    func testFolderBookmarkRoundtrip() throws {
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("ClipSlimBookmarkTest-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let watched = try FolderBookmarkManager.makeWatchedFolder(from: tempDir)
        let resolved = try FolderBookmarkManager.resolve(watched)

        XCTAssertEqual(
            resolved.url.resolvingSymlinksInPath().standardizedFileURL.path,
            tempDir.resolvingSymlinksInPath().standardizedFileURL.path
        )
    }

    func testOptimizationResultPreciseSizesUnderOneKilobyte() {
        let result = OptimizationResult(
            originalSize: 512,
            optimizedSize: 500,
            format: .png,
            duration: 0.01,
            originalDimensions: (100, 100),
            optimizedDimensions: (100, 100)
        )

        XCTAssertEqual(result.preciseOriginalSize, "512 B")
        XCTAssertEqual(result.preciseOptimizedSize, "500 B")
    }

    func testOptimizationResultPreciseSizesInKilobytes() {
        let result = OptimizationResult(
            originalSize: 85123,
            optimizedSize: 84995,
            format: .png,
            duration: 0.01,
            originalDimensions: (1070, 586),
            optimizedDimensions: (1070, 586)
        )

        XCTAssertEqual(result.preciseOriginalSize, "83.13 KB")
        XCTAssertEqual(result.preciseOptimizedSize, "83.00 KB")
    }

    func testApplyPresetDisablesQualityOverride() {
        let settings = AppSettings()
        let previousPreset = settings.selectedPreset
        let previousOverride = settings.overridePresetQuality
        defer {
            settings.selectedPreset = previousPreset
            settings.overridePresetQuality = previousOverride
        }

        settings.overridePresetQuality = true
        settings.applyPreset(.compressed)

        XCTAssertEqual(settings.selectedPreset, .compressed)
        XCTAssertFalse(settings.overridePresetQuality)
    }

    func testApplyOptimizationIntensityActivatesCustomPreset() {
        let settings = AppSettings()
        let previousPreset = settings.selectedPreset
        let previousOverride = settings.overridePresetQuality
        let previousCustomQuality = settings.customQuality
        let previousGlobalQuality = settings.globalQualityValue
        let previousIntensity = settings.optimizationIntensity
        defer {
            settings.selectedPreset = previousPreset
            settings.overridePresetQuality = previousOverride
            settings.customQuality = previousCustomQuality
            settings.globalQualityValue = previousGlobalQuality
            settings.optimizationIntensity = previousIntensity
        }

        settings.applyOptimizationIntensity(.aggressive)

        XCTAssertEqual(settings.optimizationIntensity, .aggressive)
        XCTAssertEqual(settings.selectedPreset, .custom)
        XCTAssertFalse(settings.overridePresetQuality)
        XCTAssertEqual(settings.customQuality, 0.40, accuracy: 0.001)
        XCTAssertEqual(settings.globalQualityValue, 0.40, accuracy: 0.001)
    }

    func testSettingsPersistAcrossInstances() {
        let suiteName = "ClipSlimTests-\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create isolated defaults suite")
            return
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let first = AppSettings(defaults: defaults)
        first.applyPreset(.compressed)
        first.overridePresetQuality = true
        first.globalQualityValue = 0.55
        first.applyOptimizationIntensity(.light)

        let second = AppSettings(defaults: defaults)
        XCTAssertEqual(second.selectedPreset, .custom)
        XCTAssertEqual(second.optimizationIntensity, .light)
        XCTAssertEqual(second.customQuality, 0.80, accuracy: 0.001)
        XCTAssertEqual(second.globalQualityValue, 0.80, accuracy: 0.001)
        XCTAssertFalse(second.overridePresetQuality)
    }

    func testLegacyPresetRawValueMigratesOnLoad() {
        let suiteName = "ClipSlimTests-LegacyPreset-\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create isolated defaults suite")
            return
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set("Small", forKey: "selectedPreset")

        let settings = AppSettings(defaults: defaults)
        XCTAssertEqual(settings.selectedPreset, .compressed)
        XCTAssertEqual(defaults.string(forKey: "selectedPreset"), OptimizationPreset.compressed.rawValue)
    }

    func testFirstLaunchStillRequiresOnboardingWhenNotPresented() {
        let suiteName = "ClipSlimTests-Onboarding-\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create isolated defaults suite")
            return
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(true, forKey: "onboardingCompleted")
        defaults.set(AppSettings.onboardingSchemaVersion, forKey: "onboardingSchemaVersion")
        defaults.set(false, forKey: "onboardingPresentedAtLeastOnce")

        let settings = AppSettings(defaults: defaults)
        XCTAssertTrue(settings.shouldPresentOnboarding)

        settings.markOnboardingPresented()
        settings.markOnboardingCompleted()
        XCTAssertFalse(settings.shouldPresentOnboarding)
    }
}
