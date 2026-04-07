import Foundation
import CoreGraphics

// MARK: - CodableColor

/// Stores RGBA as a 4-element array for JSON compatibility.
struct CodableColor: Codable, Sendable, Equatable {
    var red: CGFloat
    var green: CGFloat
    var blue: CGFloat
    var alpha: CGFloat

    init(red: CGFloat = 1.0, green: CGFloat = 1.0, blue: CGFloat = 1.0, alpha: CGFloat = 0.5) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    var cgColor: CGColor {
        CGColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    // Custom Codable: encode as [r, g, b, a] array
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        red = try container.decode(CGFloat.self)
        green = try container.decode(CGFloat.self)
        blue = try container.decode(CGFloat.self)
        alpha = try container.decode(CGFloat.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(red)
        try container.encode(green)
        try container.encode(blue)
        try container.encode(alpha)
    }
}

// MARK: - WatermarkType

enum WatermarkType: String, Codable, Sendable, CaseIterable {
    case text
    case image
}

// MARK: - WatermarkPosition (9-grid)

enum WatermarkPosition: String, Codable, Sendable, CaseIterable, Hashable {
    case topLeft
    case topCenter
    case topRight
    case middleLeft
    case center
    case middleRight
    case bottomLeft
    case bottomCenter
    case bottomRight

    /// Returns the origin point for a watermark of the given size within an image of the given dimensions.
    func origin(imageWidth: CGFloat, imageHeight: CGFloat, watermarkWidth: CGFloat, watermarkHeight: CGFloat, margin: CGFloat) -> CGPoint {
        let x: CGFloat
        let y: CGFloat

        switch self {
        case .topLeft, .middleLeft, .bottomLeft:
            x = margin
        case .topCenter, .center, .bottomCenter:
            x = (imageWidth - watermarkWidth) / 2
        case .topRight, .middleRight, .bottomRight:
            x = imageWidth - watermarkWidth - margin
        }

        // CoreGraphics uses bottom-left origin
        switch self {
        case .bottomLeft, .bottomCenter, .bottomRight:
            y = margin
        case .middleLeft, .center, .middleRight:
            y = (imageHeight - watermarkHeight) / 2
        case .topLeft, .topCenter, .topRight:
            y = imageHeight - watermarkHeight - margin
        }

        return CGPoint(x: x, y: y)
    }
}

// MARK: - WatermarkConfig

struct WatermarkConfig: Codable, Sendable, Equatable {
    var enabled: Bool
    var type: WatermarkType
    var text: String
    var fontName: String
    var fontSize: CGFloat
    var color: CodableColor
    var imagePath: String
    var imageOpacity: CGFloat
    var position: WatermarkPosition
    var margin: CGFloat
    var tilingEnabled: Bool
    var tilingSpacing: CGFloat

    static let `default` = WatermarkConfig(
        enabled: false,
        type: .text,
        text: "",
        fontName: "Helvetica",
        fontSize: 24.0,
        color: CodableColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.5),
        imagePath: "",
        imageOpacity: 0.5,
        position: .bottomRight,
        margin: 20.0,
        tilingEnabled: false,
        tilingSpacing: 100.0
    )
}
