import Foundation
import ArgumentParser

struct OptimizeCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "optimize",
        abstract: "Optimize a single image or PDF file."
    )

    @Argument(help: "Path to the file to optimize")
    var file: String

    @OptionGroup var options: OptimizationOptions
    @OptionGroup var global: GlobalOptions

    func run() async throws {
        let url = URL(fileURLWithPath: (file as NSString).expandingTildeInPath)

        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ValidationError("File not found: \(file)")
        }

        let data = try Data(contentsOf: url)
        let fileType = OptimizableFileType.from(data: data)

        let outputURL: URL
        if let output = options.output {
            outputURL = URL(fileURLWithPath: (output as NSString).expandingTildeInPath)
        } else {
            let baseName = url.deletingPathExtension().lastPathComponent
            let parent = url.deletingLastPathComponent()

            if case .pdf = fileType {
                outputURL = parent.appendingPathComponent("\(baseName)_optimized.pdf")
            } else {
                let ext = (options.resolvedFormat() ?? .jpeg).fileExtension
                outputURL = parent.appendingPathComponent("\(baseName)_optimized.\(ext)")
            }
        }

        if case .pdf = fileType {
            let config = PDFOptimizer.PDFOptimizationConfig(
                targetDPI: 150,
                imageQuality: options.resolvedQuality(),
                stripMetadata: options.stripMetadata
            )
            let (optimizedData, pdfResult) = try PDFOptimizer.shared.optimize(data: data, config: config)

            if !options.dryRun {
                try optimizedData.write(to: outputURL, options: .atomic)
            }

            let savings = String(format: "%.1f%%", pdfResult.savingsPercentage)
            let result = CLIResultJSON(
                input: url.path,
                inputSize: pdfResult.originalSize,
                output: outputURL.path,
                outputSize: pdfResult.optimizedSize,
                savings: savings,
                format: "pdf"
            )
            printResult(result, json: global.json, quiet: global.quiet)
        } else {
            let config = options.buildConfig()
            let (optimizedData, result) = try await ImageOptimizer.shared.optimize(data: data, config: config)

            if !options.dryRun {
                try optimizedData.write(to: outputURL, options: .atomic)
            }

            let savings = String(format: "%.1f%%", result.savingsPercentage)
            let cliResult = CLIResultJSON(
                input: url.path,
                inputSize: result.originalSize,
                output: outputURL.path,
                outputSize: result.optimizedSize,
                savings: savings,
                format: result.format.rawValue
            )
            printResult(cliResult, json: global.json, quiet: global.quiet)
        }
    }
}
