import Foundation

struct MetadataPolicy: Codable, Sendable, Equatable {

    enum Mode: String, Codable, Sendable, CaseIterable {
        case keepAll
        case stripAll
        case selective
    }

    var mode: Mode
    var keepCopyright: Bool
    var keepAuthor: Bool
    var stripGPS: Bool
    var stripCameraInfo: Bool

    init(
        mode: Mode = .stripAll,
        keepCopyright: Bool = false,
        keepAuthor: Bool = false,
        stripGPS: Bool = true,
        stripCameraInfo: Bool = true
    ) {
        self.mode = mode
        self.keepCopyright = keepCopyright
        self.keepAuthor = keepAuthor
        self.stripGPS = stripGPS
        self.stripCameraInfo = stripCameraInfo
    }

    static let stripAll = MetadataPolicy(mode: .stripAll, keepCopyright: false, keepAuthor: false, stripGPS: true, stripCameraInfo: true)
    static let keepAll = MetadataPolicy(mode: .keepAll, keepCopyright: true, keepAuthor: true, stripGPS: false, stripCameraInfo: false)

    /// When true, the optimizer can use the fast path (kCGImageDestinationOptimizeColorForSharing).
    var effectiveStripMetadata: Bool {
        mode == .stripAll
    }

    /// Whether selective filtering is needed (some keys kept, others removed).
    var requiresSelectiveFiltering: Bool {
        mode == .selective
    }

    var shouldStripGPS: Bool {
        mode == .stripAll || (mode == .selective && stripGPS)
    }

    var shouldStripCameraInfo: Bool {
        mode == .stripAll || (mode == .selective && stripCameraInfo)
    }

    var shouldKeepCopyright: Bool {
        mode == .keepAll || (mode == .selective && keepCopyright)
    }

    var shouldKeepAuthor: Bool {
        mode == .keepAll || (mode == .selective && keepAuthor)
    }

    static func fromLegacy(stripMetadata: Bool) -> MetadataPolicy {
        stripMetadata ? .stripAll : .keepAll
    }
}
