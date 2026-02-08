import Foundation

enum ImageFormat: String, Codable, CaseIterable {
    case jpeg = "JPEG"
    case png = "PNG"
    
    var fileExtension: String {
        switch self {
        case .jpeg: return "jpg"
        case .png: return "png"
        }
    }
    
    var utType: String {
        switch self {
        case .jpeg: return "public.jpeg"
        case .png: return "public.png"
        }
    }
}
