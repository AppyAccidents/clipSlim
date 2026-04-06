import XCTest
import AVFoundation
@testable import ClipSlim

final class VideoOptimizerTests: XCTestCase {

    let optimizer = VideoOptimizer.shared

    // MARK: - Helper

    /// Creates a minimal test MP4 file (1 second, solid red, 320x240)
    private func makeTestVideo(
        duration: TimeInterval = 1.0,
        width: Int = 320,
        height: Int = 240,
        includeAudio: Bool = true
    ) async throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let outputURL = tempDir.appendingPathComponent("test_\(UUID().uuidString).mp4")

        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)

        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height
        ]
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
                kCVPixelBufferWidthKey as String: width,
                kCVPixelBufferHeightKey as String: height
            ]
        )
        writer.add(videoInput)

        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        let fps = 30
        let totalFrames = Int(duration * Double(fps))

        for frameIndex in 0..<totalFrames {
            while !videoInput.isReadyForMoreMediaData {
                try await Task.sleep(nanoseconds: 10_000_000) // 10ms
            }

            var pixelBuffer: CVPixelBuffer?
            let status = CVPixelBufferCreate(
                kCFAllocatorDefault, width, height,
                kCVPixelFormatType_32ARGB, nil, &pixelBuffer
            )
            guard status == kCVReturnSuccess, let buffer = pixelBuffer else { continue }

            CVPixelBufferLockBaseAddress(buffer, [])
            if let baseAddress = CVPixelBufferGetBaseAddress(buffer) {
                let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
                let ptr = baseAddress.assumingMemoryBound(to: UInt8.self)
                for y in 0..<height {
                    for x in 0..<width {
                        let offset = y * bytesPerRow + x * 4
                        ptr[offset] = 255     // A
                        ptr[offset + 1] = 255 // R
                        ptr[offset + 2] = 0   // G
                        ptr[offset + 3] = 0   // B
                    }
                }
            }
            CVPixelBufferUnlockBaseAddress(buffer, [])

            let time = CMTime(value: CMTimeValue(frameIndex), timescale: CMTimeScale(fps))
            adaptor.append(buffer, withPresentationTime: time)
        }

        videoInput.markAsFinished()
        await writer.finishWriting()

        guard writer.status == .completed else {
            throw NSError(domain: "TestHelper", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to create test video: \(writer.error?.localizedDescription ?? "unknown")"
            ])
        }

        return outputURL
    }

    override func tearDown() {
        super.tearDown()
        // Clean up temp files
        let tempDir = FileManager.default.temporaryDirectory
        if let files = try? FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil) {
            for file in files where file.lastPathComponent.hasPrefix("test_") && file.pathExtension == "mp4" {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }

    // MARK: - Tests

    func testOptimizeH264ProducesOutput() async throws {
        let inputURL = try await makeTestVideo()
        let config = VideoOptimizationConfig(codec: .h264, quality: 0.7, maxResolution: .p1080)
        let (outputURL, result) = try await optimizer.optimize(inputURL: inputURL, config: config)

        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
        XCTAssertGreaterThan(result.optimizedSize, 0)
        XCTAssertGreaterThan(result.duration, 0)
        XCTAssertEqual(result.codec, .h264)
        XCTAssertGreaterThan(result.processingTime, 0)

        try? FileManager.default.removeItem(at: outputURL)
        try? FileManager.default.removeItem(at: inputURL)
    }

    func testOptimizeHEVCProducesOutput() async throws {
        let inputURL = try await makeTestVideo()
        let config = VideoOptimizationConfig(codec: .hevc, quality: 0.7, maxResolution: .p1080)
        let (outputURL, result) = try await optimizer.optimize(inputURL: inputURL, config: config)

        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
        XCTAssertEqual(result.codec, .hevc)
        XCTAssertGreaterThan(result.optimizedSize, 0)

        try? FileManager.default.removeItem(at: outputURL)
        try? FileManager.default.removeItem(at: inputURL)
    }

    func testMaxResolutionConstrainsOutput() async throws {
        let inputURL = try await makeTestVideo(width: 1920, height: 1080)
        let config = VideoOptimizationConfig(codec: .h264, quality: 0.7, maxResolution: .p1080)
        let (outputURL, result) = try await optimizer.optimize(inputURL: inputURL, config: config)

        XCTAssertLessThanOrEqual(max(result.resolutionWidth, result.resolutionHeight), 1920)

        try? FileManager.default.removeItem(at: outputURL)
        try? FileManager.default.removeItem(at: inputURL)
    }

    func testShortVideoOptimizes() async throws {
        let inputURL = try await makeTestVideo(duration: 0.5)
        let config = VideoOptimizationConfig(codec: .h264, quality: 0.7, maxResolution: .p1080)
        let (outputURL, result) = try await optimizer.optimize(inputURL: inputURL, config: config)

        XCTAssertGreaterThan(result.optimizedSize, 0)
        XCTAssertLessThanOrEqual(result.duration, 1.0)

        try? FileManager.default.removeItem(at: outputURL)
        try? FileManager.default.removeItem(at: inputURL)
    }

    func testResultFormattedDuration() {
        let result = VideoOptimizationResult(
            originalSize: 10_000_000,
            optimizedSize: 5_000_000,
            duration: 125.0,
            codec: .h264,
            resolutionWidth: 1920,
            resolutionHeight: 1080,
            originalBitrate: 5_000_000,
            optimizedBitrate: 2_500_000,
            processingTime: 3.5
        )

        XCTAssertEqual(result.formattedDuration, "2m 5s")
        XCTAssertEqual(result.formattedResolution, "1920x1080")
        XCTAssertEqual(result.savingsPercentage, 50.0, accuracy: 0.01)
        XCTAssertEqual(result.savingsBytes, 5_000_000)
    }

    func testResultFormattedDurationSecondsOnly() {
        let result = VideoOptimizationResult(
            originalSize: 1000,
            optimizedSize: 500,
            duration: 45.0,
            codec: .hevc,
            resolutionWidth: 320,
            resolutionHeight: 240,
            originalBitrate: 1000,
            optimizedBitrate: 500,
            processingTime: 1.0
        )

        XCTAssertEqual(result.formattedDuration, "45s")
    }

    func testVideoCodecProperties() {
        XCTAssertEqual(VideoCodec.h264.fileType, .mp4)
        XCTAssertEqual(VideoCodec.hevc.fileType, .mp4)
        XCTAssertEqual(VideoCodec.h264.rawValue, "H.264")
        XCTAssertEqual(VideoCodec.hevc.rawValue, "H.265")
    }

    func testVideoMaxResolutionLabels() {
        XCTAssertEqual(VideoMaxResolution.p1080.label, "1080p")
        XCTAssertEqual(VideoMaxResolution.p1440.label, "1440p")
        XCTAssertEqual(VideoMaxResolution.p2160.label, "4K")
    }
}
