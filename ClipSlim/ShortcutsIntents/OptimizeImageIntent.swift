import AppIntents
import Foundation

enum PresetParameter: String, AppEnum {
    case webQuality = "Web Quality"
    case highQuality = "High Quality"
    case compressed = "Compressed"

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Optimization Preset"
    }

    static var caseDisplayRepresentations: [PresetParameter: DisplayRepresentation] {
        [
            .webQuality: "Web Quality",
            .highQuality: "High Quality",
            .compressed: "Compressed"
        ]
    }

    var toOptimizationPreset: OptimizationPreset {
        switch self {
        case .webQuality: return .webQuality
        case .highQuality: return .highQuality
        case .compressed: return .compressed
        }
    }
}

enum FormatParameter: String, AppEnum {
    case jpeg = "JPEG"
    case png = "PNG"
    case webp = "WebP"
    case avif = "AVIF"

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Image Format"
    }

    static var caseDisplayRepresentations: [FormatParameter: DisplayRepresentation] {
        [
            .jpeg: "JPEG",
            .png: "PNG",
            .webp: "WebP",
            .avif: "AVIF"
        ]
    }

    var toImageFormat: ImageFormat {
        switch self {
        case .jpeg: return .jpeg
        case .png: return .png
        case .webp: return .webp
        case .avif: return .avif
        }
    }
}

struct OptimizeImageIntent: AppIntent {
    static var title: LocalizedStringResource = "Optimize Image"
    static var description = IntentDescription("Compress and optimize an image file using ClipSlim")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Image File")
    var file: IntentFile

    @Parameter(title: "Preset", default: .webQuality)
    var preset: PresetParameter?

    @Parameter(title: "Output Format")
    var outputFormat: FormatParameter?

    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        let data = file.data

        guard !data.isEmpty else {
            throw IntentError.invalidInput("Image file is empty")
        }

        let chosenPreset = (preset ?? .webQuality).toOptimizationPreset

        let config = ImageOptimizer.OptimizationConfig(
            quality: chosenPreset.quality,
            maxDimension: chosenPreset.maxDimension,
            stripMetadata: chosenPreset.stripMetadata,
            allowTransparencyLoss: chosenPreset.allowTransparencyLoss,
            preferredFormat: .jpeg,
            preserveAlphaByForcingPNG: true,
            outputFormatOverride: outputFormat?.toImageFormat,
            metadataPolicy: chosenPreset.stripMetadata ? .stripAll : .keepAll
        )

        let optimizeTask = Task.detached(priority: .utility) {
            try await ImageOptimizer.shared.optimize(data: data, config: config)
        }

        let result: (data: Data, result: OptimizationResult)
        do {
            result = try await withTimeout(seconds: 30) {
                try await optimizeTask.value
            }
        } catch {
            throw IntentError.optimizationFailed("Optimization failed or timed out: \(error.localizedDescription)")
        }

        let format = result.result.format
        let fileName = "optimized.\(format.fileExtension)"
        let outputFile = IntentFile(data: result.data, filename: fileName)

        return .result(value: outputFile)
    }

    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            group.addTask {
                try await Task.sleep(for: .seconds(seconds))
                throw IntentError.optimizationFailed("Operation timed out after \(Int(seconds)) seconds")
            }
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}

enum IntentError: Swift.Error, CustomLocalizedStringResourceConvertible {
    case invalidInput(String)
    case optimizationFailed(String)

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .invalidInput(let msg): return "Invalid input: \(msg)"
        case .optimizationFailed(let msg): return "Optimization failed: \(msg)"
        }
    }
}
