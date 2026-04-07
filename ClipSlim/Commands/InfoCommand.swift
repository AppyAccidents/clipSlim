import Foundation
import ArgumentParser
import ImageIO

struct InfoCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "info",
        abstract: "Show information about an image or PDF file."
    )

    @Argument(help: "Path to the file")
    var file: String

    @OptionGroup var global: GlobalOptions

    func run() async throws {
        let url = URL(fileURLWithPath: (file as NSString).expandingTildeInPath)

        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ValidationError("File not found: \(file)")
        }

        let data = try Data(contentsOf: url)
        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = (attrs[.size] as? Int) ?? data.count
        let fileType = OptimizableFileType.from(data: data)

        if case .pdf = fileType {
            printPDFInfo(url: url, data: data, fileSize: fileSize)
        } else {
            printImageInfo(url: url, data: data, fileSize: fileSize)
        }
    }

    private func printImageInfo(url: URL, data: Data, fileSize: Int) {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            print("Error: Cannot read image data")
            return
        }

        let type = (CGImageSourceGetType(source) as String?) ?? "unknown"
        let imageCount = CGImageSourceGetCount(source)

        var width = 0
        var height = 0
        var hasAlpha = false

        if let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] {
            width = properties[kCGImagePropertyPixelWidth] as? Int ?? 0
            height = properties[kCGImagePropertyPixelHeight] as? Int ?? 0
            hasAlpha = properties[kCGImagePropertyHasAlpha] as? Bool ?? false
        }

        let format = detectFormat(from: type)

        if global.json {
            let info: [String: Any] = [
                "path": url.path,
                "format": format,
                "width": width,
                "height": height,
                "fileSize": fileSize,
                "hasAlpha": hasAlpha,
                "imageCount": imageCount,
            ]
            if let jsonData = try? JSONSerialization.data(withJSONObject: info, options: [.prettyPrinted, .sortedKeys]),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
            }
        } else {
            print("File:       \(url.lastPathComponent)")
            print("Format:     \(format)")
            print("Dimensions: \(width) x \(height)")
            print("File size:  \(formatBytes(fileSize))")
            print("Has alpha:  \(hasAlpha ? "yes" : "no")")
            if imageCount > 1 {
                print("Frames:     \(imageCount)")
            }
        }
    }

    private func printPDFInfo(url: URL, data: Data, fileSize: Int) {
        guard let provider = CGDataProvider(data: data as CFData),
              let document = CGPDFDocument(provider) else {
            print("Error: Cannot read PDF")
            return
        }

        let pageCount = document.numberOfPages

        if global.json {
            let info: [String: Any] = [
                "path": url.path,
                "format": "pdf",
                "pageCount": pageCount,
                "fileSize": fileSize,
            ]
            if let jsonData = try? JSONSerialization.data(withJSONObject: info, options: [.prettyPrinted, .sortedKeys]),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
            }
        } else {
            print("File:       \(url.lastPathComponent)")
            print("Format:     PDF")
            print("Pages:      \(pageCount)")
            print("File size:  \(formatBytes(fileSize))")
        }
    }

    private func detectFormat(from utiString: String) -> String {
        let lower = utiString.lowercased()
        if lower.contains("png") { return "png" }
        if lower.contains("jpeg") || lower.contains("jpg") { return "jpeg" }
        if lower.contains("webp") { return "webp" }
        if lower.contains("heic") || lower.contains("heif") { return "heic" }
        if lower.contains("tiff") { return "tiff" }
        if lower.contains("bmp") { return "bmp" }
        if lower.contains("gif") { return "gif" }
        return utiString
    }

    private func formatBytes(_ bytes: Int) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        let kb = Double(bytes) / 1024.0
        if kb < 1024 { return String(format: "%.1f KB", kb) }
        let mb = kb / 1024.0
        return String(format: "%.2f MB", mb)
    }
}
