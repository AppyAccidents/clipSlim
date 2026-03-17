import Foundation
import CoreGraphics
import ImageIO

final class QualityScorer: Sendable {
    static let shared = QualityScorer()
    private init() {}

    /// Compute simplified SSIM between original and optimized image data.
    /// Both images are downsampled to 256x256 grayscale.
    /// Returns 0.0–1.0 where 1.0 = identical.
    func computeSSIM(original: Data, optimized: Data) -> Double {
        let size = 256
        guard let origGray = toGrayscale(data: original, size: size),
              let optGray = toGrayscale(data: optimized, size: size) else {
            return 1.0 // If we can't compute, assume OK
        }

        let n = size * size
        var sumX = 0.0, sumY = 0.0
        var sumX2 = 0.0, sumY2 = 0.0
        var sumXY = 0.0

        for i in 0..<n {
            let x = Double(origGray[i])
            let y = Double(optGray[i])
            sumX += x
            sumY += y
            sumX2 += x * x
            sumY2 += y * y
            sumXY += x * y
        }

        let count = Double(n)
        let meanX = sumX / count
        let meanY = sumY / count
        let varX = sumX2 / count - meanX * meanX
        let varY = sumY2 / count - meanY * meanY
        let covXY = sumXY / count - meanX * meanY

        // SSIM constants (for 8-bit: L=255)
        let c1 = 6.5025   // (0.01 * 255)^2
        let c2 = 58.5225  // (0.03 * 255)^2

        let numerator = (2 * meanX * meanY + c1) * (2 * covXY + c2)
        let denominator = (meanX * meanX + meanY * meanY + c1) * (varX + varY + c2)

        guard denominator > 0 else { return 1.0 }
        return max(0, min(1, numerator / denominator))
    }

    private func toGrayscale(data: Data, size: Int) -> [UInt8]? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return nil
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerRow = size * 4
        guard let context = CGContext(
            data: nil, width: size, height: size,
            bitsPerComponent: 8, bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.interpolationQuality = .medium
        context.draw(image, in: CGRect(x: 0, y: 0, width: size, height: size))

        guard let pixelData = context.data else { return nil }
        let buffer = pixelData.bindMemory(to: UInt8.self, capacity: size * size * 4)

        var gray = [UInt8](repeating: 0, count: size * size)
        for i in 0..<(size * size) {
            let offset = i * 4
            // Luminance: 0.299R + 0.587G + 0.114B
            let r = Double(buffer[offset])
            let g = Double(buffer[offset + 1])
            let b = Double(buffer[offset + 2])
            gray[i] = UInt8(min(255, 0.299 * r + 0.587 * g + 0.114 * b))
        }

        return gray
    }
}
