import Foundation
import UniformTypeIdentifiers

enum ImageFormat: String, Codable, CaseIterable {
    case jpeg = "JPEG"
    case png = "PNG"
    case webp = "WebP"
    case avif = "AVIF"

    var fileExtension: String {
        switch self {
        case .jpeg: return "jpg"
        case .png: return "png"
        case .webp: return "webp"
        case .avif: return "avif"
        }
    }

    var utType: String {
        switch self {
        case .jpeg: return UTType.jpeg.identifier
        case .png: return UTType.png.identifier
        case .webp: return UTType.webP.identifier
        case .avif: return "public.avif"
        }
    }
}
