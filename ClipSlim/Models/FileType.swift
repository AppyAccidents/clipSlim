import Foundation

enum OptimizableFileType {
    case image(ImageFormat)
    case pdf
    case video
    case gif
    case svg

    static func from(url: URL) -> OptimizableFileType? {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "gif":
            return .gif
        case "svg":
            return .svg
        case "mp4", "mov", "m4v":
            return .video
        case "jpg", "jpeg":
            return .image(.jpeg)
        case "png":
            return .image(.png)
        case "tiff", "tif", "bmp", "heic":
            return .image(.png)
        case "webp":
            return .image(.webp)
        case "pdf":
            return .pdf
        default:
            return nil
        }
    }

    static func from(data: Data) -> OptimizableFileType? {
        guard data.count >= 6 else { return nil }
        let header = data.prefix(6)

        // PDF: %PDF-
        if header.starts(with: [0x25, 0x50, 0x44, 0x46, 0x2D]) {
            return .pdf
        }

        // GIF: GIF87a or GIF89a
        if header.starts(with: [0x47, 0x49, 0x46, 0x38]) {
            let version = data[data.startIndex + 4]
            if version == 0x37 || version == 0x39 { // '7' or '9'
                return .gif
            }
        }

        // SVG: starts with "<?xml" or "<svg" (check UTF-8 text)
        if let prefix = String(data: data.prefix(256), encoding: .utf8) {
            let trimmed = prefix.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if trimmed.hasPrefix("<?xml") || trimmed.hasPrefix("<svg") {
                return .svg
            }
        }

        // Video: check for ftyp box (MP4/MOV container)
        if data.count >= 8 {
            let ftypOffset = data.startIndex + 4
            let ftyp = data[ftypOffset..<(ftypOffset + 4)]
            if ftyp.elementsEqual([0x66, 0x74, 0x79, 0x70]) { // "ftyp"
                return .video
            }
        }

        return nil // Assume image if not detected (let ImageOptimizer handle format detection)
    }

    var isPDF: Bool {
        if case .pdf = self { return true }
        return false
    }

    var isVideo: Bool {
        if case .video = self { return true }
        return false
    }

    var isGIF: Bool {
        if case .gif = self { return true }
        return false
    }

    var isSVG: Bool {
        if case .svg = self { return true }
        return false
    }
}
