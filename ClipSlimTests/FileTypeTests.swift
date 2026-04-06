import XCTest
@testable import ClipSlim

final class FileTypeTests: XCTestCase {

    // MARK: - URL Detection

    func testDetectsMP4FromURL() {
        let url = URL(fileURLWithPath: "/tmp/test.mp4")
        let result = OptimizableFileType.from(url: url)
        XCTAssertNotNil(result)
        if case .video = result {} else { XCTFail("Expected .video, got \(String(describing: result))") }
    }

    func testDetectsMOVFromURL() {
        let url = URL(fileURLWithPath: "/tmp/test.mov")
        let result = OptimizableFileType.from(url: url)
        XCTAssertNotNil(result)
        if case .video = result {} else { XCTFail("Expected .video, got \(String(describing: result))") }
    }

    func testDetectsM4VFromURL() {
        let url = URL(fileURLWithPath: "/tmp/test.m4v")
        let result = OptimizableFileType.from(url: url)
        XCTAssertNotNil(result)
        if case .video = result {} else { XCTFail("Expected .video, got \(String(describing: result))") }
    }

    func testDetectsGIFFromURL() {
        let url = URL(fileURLWithPath: "/tmp/test.gif")
        let result = OptimizableFileType.from(url: url)
        XCTAssertNotNil(result)
        if case .gif = result {} else { XCTFail("Expected .gif, got \(String(describing: result))") }
    }

    func testDetectsSVGFromURL() {
        let url = URL(fileURLWithPath: "/tmp/test.svg")
        let result = OptimizableFileType.from(url: url)
        XCTAssertNotNil(result)
        if case .svg = result {} else { XCTFail("Expected .svg, got \(String(describing: result))") }
    }

    func testDetectsJPEGFromURL() {
        let url = URL(fileURLWithPath: "/tmp/photo.jpg")
        let result = OptimizableFileType.from(url: url)
        XCTAssertNotNil(result)
        if case .image(.jpeg) = result {} else { XCTFail("Expected .image(.jpeg), got \(String(describing: result))") }
    }

    func testDetectsPDFFromURL() {
        let url = URL(fileURLWithPath: "/tmp/doc.pdf")
        let result = OptimizableFileType.from(url: url)
        XCTAssertNotNil(result)
        XCTAssertTrue(result?.isPDF ?? false)
    }

    func testUnknownExtensionReturnsNil() {
        let url = URL(fileURLWithPath: "/tmp/file.xyz")
        XCTAssertNil(OptimizableFileType.from(url: url))
    }

    // MARK: - Data Header Detection

    func testDetectsGIF89aFromData() {
        var data = Data("GIF89a".utf8)
        data.append(Data(repeating: 0x00, count: 10))
        let result = OptimizableFileType.from(data: data)
        XCTAssertNotNil(result)
        if case .gif = result {} else { XCTFail("Expected .gif, got \(String(describing: result))") }
    }

    func testDetectsGIF87aFromData() {
        var data = Data("GIF87a".utf8)
        data.append(Data(repeating: 0x00, count: 10))
        let result = OptimizableFileType.from(data: data)
        XCTAssertNotNil(result)
        if case .gif = result {} else { XCTFail("Expected .gif, got \(String(describing: result))") }
    }

    func testDetectsSVGFromXMLData() {
        let svgString = "<?xml version=\"1.0\"?><svg xmlns=\"http://www.w3.org/2000/svg\"></svg>"
        let data = Data(svgString.utf8)
        let result = OptimizableFileType.from(data: data)
        XCTAssertNotNil(result)
        if case .svg = result {} else { XCTFail("Expected .svg, got \(String(describing: result))") }
    }

    func testDetectsSVGFromSvgTagData() {
        let svgString = "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\"></svg>"
        let data = Data(svgString.utf8)
        let result = OptimizableFileType.from(data: data)
        XCTAssertNotNil(result)
        if case .svg = result {} else { XCTFail("Expected .svg, got \(String(describing: result))") }
    }

    func testDetectsMP4FromFtypHeader() {
        // Minimal ftyp box: 4 bytes size + "ftyp" + brand
        var data = Data([0x00, 0x00, 0x00, 0x14]) // size = 20
        data.append(Data("ftyp".utf8))             // box type
        data.append(Data("isom".utf8))             // brand
        data.append(Data(repeating: 0x00, count: 8))
        let result = OptimizableFileType.from(data: data)
        XCTAssertNotNil(result)
        if case .video = result {} else { XCTFail("Expected .video, got \(String(describing: result))") }
    }

    func testDetectsPDFFromData() {
        let data = Data("%PDF-1.4 test content".utf8)
        let result = OptimizableFileType.from(data: data)
        XCTAssertNotNil(result)
        XCTAssertTrue(result?.isPDF ?? false)
    }

    func testConvenienceProperties() {
        XCTAssertTrue(OptimizableFileType.pdf.isPDF)
        XCTAssertTrue(OptimizableFileType.video.isVideo)
        XCTAssertTrue(OptimizableFileType.gif.isGIF)
        XCTAssertTrue(OptimizableFileType.svg.isSVG)
        XCTAssertFalse(OptimizableFileType.video.isPDF)
        XCTAssertFalse(OptimizableFileType.pdf.isVideo)
    }
}
