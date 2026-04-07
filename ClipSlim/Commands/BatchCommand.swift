import Foundation
import ArgumentParser

struct BatchCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "batch",
        abstract: "Optimize all supported files in a directory."
    )

    @Argument(help: "Path to the directory")
    var directory: String

    @Flag(name: .long, help: "Traverse subdirectories")
    var recursive = false

    @Option(name: .long, help: "Rename template, e.g. \"{name}_{date}.{ext}\"")
    var rename: String?

    @OptionGroup var options: OptimizationOptions
    @OptionGroup var global: GlobalOptions

    private static let supportedExtensions: Set<String> = [
        "jpg", "jpeg", "png", "webp", "heic", "tiff", "tif", "bmp", "pdf"
    ]

    func run() async throws {
        let dirURL = URL(fileURLWithPath: (directory as NSString).expandingTildeInPath)
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: dirURL.path, isDirectory: &isDir), isDir.boolValue else {
            throw ValidationError("Directory not found: \(directory)")
        }

        let enumerator: FileManager.DirectoryEnumerator?
        if recursive {
            enumerator = FileManager.default.enumerator(at: dirURL, includingPropertiesForKeys: [.isRegularFileKey])
        } else {
            enumerator = FileManager.default.enumerator(at: dirURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsSubdirectoryDescendants])
        }

        guard let enumerator else {
            throw ValidationError("Cannot enumerate directory: \(directory)")
        }

        var sequenceNumber = 1
        var totalFiles = 0
        var totalSaved = 0

        for case let fileURL as URL in enumerator {
            let ext = fileURL.pathExtension.lowercased()
            guard Self.supportedExtensions.contains(ext) else { continue }

            // Skip files in "Optimized" subdirectories to avoid re-processing
            if fileURL.path.contains("/Optimized/") { continue }

            do {
                let data = try Data(contentsOf: fileURL)
                let fileType = OptimizableFileType.from(data: data)

                let outputURL: URL
                if let renameTemplate = rename {
                    let formatExt: String
                    if case .pdf = fileType {
                        formatExt = "pdf"
                    } else {
                        formatExt = (options.resolvedFormat() ?? .jpeg).fileExtension
                    }

                    let context = RenameContext(
                        originalName: fileURL.deletingPathExtension().lastPathComponent,
                        outputExtension: formatExt,
                        date: Date(),
                        sequenceNumber: sequenceNumber,
                        width: 0, height: 0,
                        formatName: formatExt,
                        presetName: options.preset,
                        savingsPercent: 0
                    )
                    let renamedBase = BatchRenamer.rename(template: renameTemplate, context: context)
                    outputURL = fileURL.deletingLastPathComponent()
                        .appendingPathComponent("\(renamedBase).\(formatExt)")
                } else if let output = options.output {
                    let outDir = URL(fileURLWithPath: (output as NSString).expandingTildeInPath)
                    let baseName = fileURL.deletingPathExtension().lastPathComponent
                    let formatExt: String
                    if case .pdf = fileType { formatExt = "pdf" }
                    else { formatExt = (options.resolvedFormat() ?? .jpeg).fileExtension }
                    outputURL = outDir.appendingPathComponent("\(baseName)_optimized.\(formatExt)")
                } else {
                    let baseName = fileURL.deletingPathExtension().lastPathComponent
                    if case .pdf = fileType {
                        outputURL = fileURL.deletingLastPathComponent()
                            .appendingPathComponent("\(baseName)_optimized.pdf")
                    } else {
                        let formatExt = (options.resolvedFormat() ?? .jpeg).fileExtension
                        outputURL = fileURL.deletingLastPathComponent()
                            .appendingPathComponent("\(baseName)_optimized.\(formatExt)")
                    }
                }

                if case .pdf = fileType {
                    let config = PDFOptimizer.PDFOptimizationConfig(
                        targetDPI: 150,
                        imageQuality: options.resolvedQuality(),
                        stripMetadata: options.stripMetadata
                    )
                    let (optimizedData, pdfResult) = try PDFOptimizer.shared.optimize(data: data, config: config)
                    guard pdfResult.optimizedSize < pdfResult.originalSize else { continue }

                    if !options.dryRun {
                        try FileManager.default.createDirectory(
                            at: outputURL.deletingLastPathComponent(),
                            withIntermediateDirectories: true
                        )
                        try optimizedData.write(to: outputURL, options: .atomic)
                    }

                    let savings = String(format: "%.1f%%", pdfResult.savingsPercentage)
                    printResult(CLIResultJSON(
                        input: fileURL.path, inputSize: pdfResult.originalSize,
                        output: outputURL.path, outputSize: pdfResult.optimizedSize,
                        savings: savings, format: "pdf"
                    ), json: global.json, quiet: global.quiet)
                    totalSaved += pdfResult.originalSize - pdfResult.optimizedSize
                } else {
                    let config = options.buildConfig()
                    let (optimizedData, result) = try await ImageOptimizer.shared.optimize(data: data, config: config)
                    guard result.optimizedSize < result.originalSize else { continue }

                    if !options.dryRun {
                        try FileManager.default.createDirectory(
                            at: outputURL.deletingLastPathComponent(),
                            withIntermediateDirectories: true
                        )
                        try optimizedData.write(to: outputURL, options: .atomic)
                    }

                    let savings = String(format: "%.1f%%", result.savingsPercentage)
                    printResult(CLIResultJSON(
                        input: fileURL.path, inputSize: result.originalSize,
                        output: outputURL.path, outputSize: result.optimizedSize,
                        savings: savings, format: result.format.rawValue
                    ), json: global.json, quiet: global.quiet)
                    totalSaved += result.originalSize - result.optimizedSize
                }

                totalFiles += 1
                sequenceNumber += 1
            } catch {
                if !global.quiet {
                    FileHandle.standardError.write(Data("Error processing \(fileURL.lastPathComponent): \(error.localizedDescription)\n".utf8))
                }
            }
        }

        if !global.quiet && !global.json {
            let savedMB = String(format: "%.2f", Double(totalSaved) / (1024 * 1024))
            print("\nDone: \(totalFiles) files optimized, \(savedMB) MB saved total")
        }
    }
}
