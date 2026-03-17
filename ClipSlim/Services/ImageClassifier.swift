import Foundation
import CoreGraphics
import ImageIO

/// F11: Semantic image classification using pure heuristics (no Vision framework)
final class ImageClassifier: Sendable {

    static let shared = ImageClassifier()

    private init() {}

    enum ImageContentType: String, Sendable, Codable {
        case screenshot
        case photo
        case uiElement
        case mixed
    }

    func classify(data: Data) -> ImageContentType {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return .mixed
        }

        let width = image.width
        let height = image.height
        guard width > 0, height > 0 else { return .mixed }

        let aspectScore = aspectRatioScore(width: width, height: height)
        let (edgeDensity, uniformRegionRatio) = analyzePixels(image: image)
        let colorVariance = colorHistogramVariance(image: image)

        // Screenshot: common screen ratios, high edge density (UI elements), many uniform regions
        if aspectScore > 0.7 && edgeDensity > 0.12 && uniformRegionRatio > 0.3 {
            return .screenshot
        }

        // UI Element: very high uniform regions, low color variance
        if uniformRegionRatio > 0.6 && colorVariance < 800 {
            return .uiElement
        }

        // Photo: high color variance, low uniform regions
        if colorVariance > 2000 && uniformRegionRatio < 0.2 {
            return .photo
        }

        // Screenshot fallback: matching aspect ratio with moderate edges
        if aspectScore > 0.8 && edgeDensity > 0.08 {
            return .screenshot
        }

        // Photo fallback: enough color complexity
        if colorVariance > 1200 {
            return .photo
        }

        return .mixed
    }

    // MARK: - Heuristics

    /// Score how well width:height matches common screen ratios
    private func aspectRatioScore(width: Int, height: Int) -> Double {
        let ratio = Double(width) / Double(height)
        let commonRatios = [16.0/10.0, 16.0/9.0, 4.0/3.0, 3.0/2.0, 21.0/9.0,
                           10.0/16.0, 9.0/16.0, 3.0/4.0, 2.0/3.0, 9.0/21.0]

        var bestMatch = 0.0
        for target in commonRatios {
            let diff = abs(ratio - target) / target
            let match = max(0, 1.0 - diff * 5.0) // 20% tolerance
            bestMatch = max(bestMatch, match)
        }
        return bestMatch
    }

    /// Compute edge density and uniform region ratio from a downsampled image
    private func analyzePixels(image: CGImage) -> (edgeDensity: Double, uniformRegionRatio: Double) {
        let sampleSize = 128
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerRow = sampleSize * 4

        guard let context = CGContext(
            data: nil, width: sampleSize, height: sampleSize,
            bitsPerComponent: 8, bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return (0, 0)
        }

        context.interpolationQuality = .low
        context.draw(image, in: CGRect(x: 0, y: 0, width: sampleSize, height: sampleSize))

        guard let data = context.data else { return (0, 0) }
        let buffer = data.bindMemory(to: UInt8.self, capacity: sampleSize * sampleSize * 4)

        var edgePixels = 0
        var uniformPixels = 0
        let totalComparisons = (sampleSize - 1) * (sampleSize - 1)
        let edgeThreshold: Int = 30
        let uniformThreshold: Int = 5

        for y in 0..<(sampleSize - 1) {
            for x in 0..<(sampleSize - 1) {
                let idx = (y * sampleSize + x) * 4
                let rightIdx = idx + 4
                let belowIdx = ((y + 1) * sampleSize + x) * 4

                let r = Int(buffer[idx])
                let g = Int(buffer[idx + 1])
                let b = Int(buffer[idx + 2])

                let rRight = Int(buffer[rightIdx])
                let gRight = Int(buffer[rightIdx + 1])
                let bRight = Int(buffer[rightIdx + 2])

                let rBelow = Int(buffer[belowIdx])
                let gBelow = Int(buffer[belowIdx + 1])
                let bBelow = Int(buffer[belowIdx + 2])

                let gradH = abs(r - rRight) + abs(g - gRight) + abs(b - bRight)
                let gradV = abs(r - rBelow) + abs(g - gBelow) + abs(b - bBelow)
                let gradient = (gradH + gradV) / 2

                if gradient > edgeThreshold {
                    edgePixels += 1
                }
                if gradient < uniformThreshold {
                    uniformPixels += 1
                }
            }
        }

        let edgeDensity = Double(edgePixels) / Double(totalComparisons)
        let uniformRatio = Double(uniformPixels) / Double(totalComparisons)

        return (edgeDensity, uniformRatio)
    }

    /// Compute color histogram variance from an 80x80 downsample
    private func colorHistogramVariance(image: CGImage) -> Double {
        let thumbSize = 80
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerRow = thumbSize * 4

        guard let ctx = CGContext(
            data: nil, width: thumbSize, height: thumbSize,
            bitsPerComponent: 8, bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return 0
        }

        ctx.draw(image, in: CGRect(x: 0, y: 0, width: thumbSize, height: thumbSize))
        guard let data = ctx.data else { return 0 }
        let buffer = data.bindMemory(to: UInt8.self, capacity: thumbSize * thumbSize * 4)

        // Quantize to 16 bins per channel
        let binCount = 16
        var histogram = [Int](repeating: 0, count: binCount * binCount * binCount)
        let totalPixels = thumbSize * thumbSize

        for i in stride(from: 0, to: totalPixels * 4, by: 4) {
            let rBin = Int(buffer[i]) >> 4
            let gBin = Int(buffer[i + 1]) >> 4
            let bBin = Int(buffer[i + 2]) >> 4
            histogram[rBin * binCount * binCount + gBin * binCount + bBin] += 1
        }

        // Variance of histogram counts
        let mean = Double(totalPixels) / Double(histogram.count)
        var variance = 0.0
        for count in histogram {
            let diff = Double(count) - mean
            variance += diff * diff
        }
        variance /= Double(histogram.count)

        return variance
    }
}
