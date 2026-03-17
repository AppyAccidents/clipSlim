import Foundation

enum OptimizableFileType {
    case image(ImageFormat)
    case pdf

    static func from(url: URL) -> OptimizableFileType? {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "jpg", "jpeg":
            return .image(.jpeg)
        case "png":
            return .image(.png)
        case "tiff", "tif", "bmp", "heic":
            return .image(.png) // These get processed as images, output format decided by settings
        case "webp":
            return .image(.webp)
        case "pdf":
            return .pdf
        default:
            return nil
        }
    }

    static func from(data: Data) -> OptimizableFileType? {
        guard data.count >= 5 else { return nil }
        let header = data.prefix(5)
        if header.starts(with: [0x25, 0x50, 0x44, 0x46, 0x2D]) { // %PDF-
            return .pdf
        }
        return nil // Assume image if not PDF (let ImageOptimizer handle format detection)
    }

    var isPDF: Bool {
        if case .pdf = self { return true }
        return false
    }
}
