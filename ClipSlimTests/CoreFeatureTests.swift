import XCTest
import AppKit
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

    func testSaveToDiskDefaultsToTrueOnFreshDefaults() {
        let suiteName = "ClipSlimTests-SaveToDiskDefault-\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create isolated defaults suite")
            return
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = AppSettings(defaults: defaults)
        XCTAssertTrue(settings.saveToDisk)
    }

    func testClipboardWatcherRejectsPDFPasteboardType() {
        let pdfType = NSPasteboard.PasteboardType("com.adobe.pdf")
        XCTAssertFalse(ClipboardWatcher.isSupportedImagePasteboardType(pdfType))
    }

    func testClipboardWatcherAcceptsImagePasteboardTypes() {
        XCTAssertTrue(ClipboardWatcher.isSupportedImagePasteboardType(.png))
        XCTAssertTrue(ClipboardWatcher.isSupportedImagePasteboardType(.tiff))
        XCTAssertTrue(ClipboardWatcher.isSupportedImagePasteboardType(NSPasteboard.PasteboardType("public.jpeg")))
    }

    func testFolderWatcherRejectsPDFAndNonImageExtensions() {
        XCTAssertFalse(FolderWatcher.isSupportedImageFileExtension("pdf"))
        XCTAssertFalse(FolderWatcher.isSupportedImageFileExtension("txt"))
    }

    func testFolderWatcherAcceptsSupportedImageExtensions() {
        XCTAssertTrue(FolderWatcher.isSupportedImageFileExtension("jpg"))
        XCTAssertTrue(FolderWatcher.isSupportedImageFileExtension("JPEG"))
        XCTAssertTrue(FolderWatcher.isSupportedImageFileExtension("heic"))
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

    func testCurrentSlimmingPercentageForCommonValues() {
        let suiteName = "ClipSlimTests-SlimmingCommon-\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create isolated defaults suite")
            return
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = AppSettings(defaults: defaults)
        settings.overridePresetQuality = true
        settings.globalQualityValue = 0.60

        XCTAssertEqual(settings.currentSlimmingPercentage, 40)
    }

    func testCurrentSlimmingPercentageClampsToBounds() {
        let suiteName = "ClipSlimTests-SlimmingClamp-\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create isolated defaults suite")
            return
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = AppSettings(defaults: defaults)
        settings.overridePresetQuality = true

        settings.globalQualityValue = 0.0
        XCTAssertEqual(settings.currentSlimmingPercentage, 100)

        settings.globalQualityValue = 1.0
        XCTAssertEqual(settings.currentSlimmingPercentage, 0)

        settings.globalQualityValue = 1.4
        XCTAssertEqual(settings.currentSlimmingPercentage, 0)

        settings.globalQualityValue = -0.2
        XCTAssertEqual(settings.currentSlimmingPercentage, 100)
    }

    func testPauseDeadlineDurationsAndResumeTransition() {
        let now = Date(timeIntervalSince1970: 1_735_689_600) // Jan 1, 2025 00:00:00 UTC

        let tenMinute = AppViewModel.pauseDeadline(now: now, minutes: 10)
        XCTAssertEqual(tenMinute.timeIntervalSince(now), 10 * 60, accuracy: 0.001)

        let oneHour = AppViewModel.pauseDeadline(now: now, hours: 1)
        XCTAssertEqual(oneHour.timeIntervalSince(now), 60 * 60, accuracy: 0.001)

        let oneDay = AppViewModel.pauseDeadline(now: now, days: 1)
        XCTAssertEqual(oneDay.timeIntervalSince(now), 24 * 60 * 60, accuracy: 0.001)

        let suiteName = "ClipSlimTests-PauseResume-\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create isolated defaults suite")
            return
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = AppSettings(defaults: defaults)
        settings.pauseUntil = Date().addingTimeInterval(3600)
        XCTAssertTrue(settings.isPausedNow)

        settings.pauseUntil = nil
        XCTAssertFalse(settings.isPausedNow)
    }

    func testFolderWatcherSignatureIsStableAndOrderIndependent() {
        let idA = UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!
        let idB = UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!
        let folderA = WatchedFolder(id: idA, displayName: "alpha", bookmarkData: Data("a".utf8))
        let folderB = WatchedFolder(id: idB, displayName: "beta", bookmarkData: Data("b".utf8))

        let firstSignature = AppViewModel.folderWatcherSignature(for: [folderA, folderB])
        let reversedSignature = AppViewModel.folderWatcherSignature(for: [folderB, folderA])
        XCTAssertEqual(firstSignature, reversedSignature)

        let changedFolderB = WatchedFolder(id: idB, displayName: "beta", bookmarkData: Data("changed".utf8))
        let changedSignature = AppViewModel.folderWatcherSignature(for: [folderA, changedFolderB])
        XCTAssertNotEqual(firstSignature, changedSignature)
    }
}
