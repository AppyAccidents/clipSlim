import Foundation
import ArgumentParser

@main
struct ClipSlimCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "clipslim",
        abstract: "ClipSlim — image and PDF optimization from the command line.",
        version: "2.0.0",
        subcommands: [
            OptimizeCommand.self,
            BatchCommand.self,
            WatchCommand.self,
            InfoCommand.self,
        ]
    )
}

/// Shared options for output formatting.
struct GlobalOptions: ParsableArguments {
    @Flag(name: .long, help: "Output as JSON (for scripting)")
    var json = false

    @Flag(name: .long, help: "Suppress non-error output")
    var quiet = false
}

/// Shared options for optimization configuration.
struct OptimizationOptions: ParsableArguments {
    @Option(name: .long, help: "Preset: web, high, compressed, lossless, custom")
    var preset: String = "web"

    @Option(name: .long, help: "Output format: jpeg, png, webp, avif")
    var format: String?

    @Option(name: .long, help: "Quality (0.0-1.0)")
    var quality: Double?

    @Option(name: .long, help: "Max dimension in pixels")
    var maxDimension: Int?

    @Flag(name: .long, help: "Strip image metadata")
    var stripMetadata = false

    @Option(name: .shortAndLong, help: "Output path (default: alongside original with _optimized suffix)")
    var output: String?

    @Flag(name: .long, help: "Show what would happen without writing")
    var dryRun = false

    func resolvedPreset() -> OptimizationPreset {
        switch preset.lowercased() {
        case "web": return .webQuality
        case "high": return .highQuality
        case "compressed": return .compressed
        case "lossless": return .lossless
        case "custom": return .custom
        default: return .webQuality
        }
    }

    func resolvedFormat() -> ImageFormat? {
        guard let format else { return nil }
        // ImageFormat raw values are uppercase (e.g. "JPEG", "PNG")
        // Accept case-insensitive input from the CLI
        let upper = format.uppercased()
        return ImageFormat(rawValue: upper)
    }

    func resolvedQuality() -> Double {
        if let quality { return max(0.0, min(1.0, quality)) }
        return resolvedPreset().quality
    }

    func resolvedMaxDimension() -> Int {
        if let maxDimension { return max(16, min(8192, maxDimension)) }
        return resolvedPreset().maxDimension
    }

    func buildConfig() -> ImageOptimizer.OptimizationConfig {
        ImageOptimizer.OptimizationConfig(
            quality: resolvedQuality(),
            maxDimension: resolvedMaxDimension(),
            stripMetadata: stripMetadata,
            allowTransparencyLoss: false,
            preferredFormat: resolvedFormat() ?? .jpeg,
            preserveAlphaByForcingPNG: true,
            outputFormatOverride: resolvedFormat(),
            metadataPolicy: stripMetadata ? .stripAll : .keepAll
        )
    }
}

/// JSON output structure for a single optimization result.
struct CLIResultJSON: Codable {
    let input: String
    let inputSize: Int
    let output: String
    let outputSize: Int
    let savings: String
    let format: String
}

func printResult(_ result: CLIResultJSON, json: Bool, quiet: Bool) {
    if json {
        if let data = try? JSONEncoder().encode(result),
           let string = String(data: data, encoding: .utf8) {
            print(string)
        }
    } else if !quiet {
        let percent = result.savings
        print("\(result.input) -> \(result.output) (\(percent) saved, \(result.format))")
    }
}
