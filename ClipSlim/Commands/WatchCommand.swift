import Foundation
import ArgumentParser

struct WatchCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "watch",
        abstract: "Watch a directory and optimize new files as they appear."
    )

    @Argument(help: "Path to the directory to watch")
    var directory: String

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

        if !global.quiet {
            print("Watching \(dirURL.path) for new images and PDFs... (Ctrl+C to stop)")
        }

        // Track existing files to only process new ones
        var knownFiles = Set<String>()
        if let contents = try? FileManager.default.contentsOfDirectory(atPath: dirURL.path) {
            for item in contents {
                knownFiles.insert(item)
            }
        }

        // Set up SIGINT handler
        let sigintSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        signal(SIGINT, SIG_IGN) // Ignore default handler
        sigintSource.setEventHandler {
            if !self.global.quiet {
                print("\nStopping watch...")
            }
            exit(0)
        }
        sigintSource.resume()

        // Set up file system watcher using DispatchSource
        let fd = open(dirURL.path, O_EVTONLY)
        guard fd >= 0 else {
            throw ValidationError("Cannot open directory for watching: \(directory)")
        }

        let fsSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: .write,
            queue: .main
        )

        // Debounce timer
        var debounceWorkItem: DispatchWorkItem?
        let debounceInterval: TimeInterval = 0.3

        fsSource.setEventHandler {
            debounceWorkItem?.cancel()
            let workItem = DispatchWorkItem {
                Task {
                    await self.processNewFiles(in: dirURL, knownFiles: &knownFiles)
                }
            }
            debounceWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + debounceInterval, execute: workItem)
        }

        fsSource.setCancelHandler {
            close(fd)
        }

        fsSource.resume()

        // Keep the run loop alive
        RunLoop.current.run()
    }

    private func processNewFiles(in dirURL: URL, knownFiles: inout Set<String>) async {
        guard let contents = try? FileManager.default.contentsOfDirectory(atPath: dirURL.path) else { return }

        for item in contents {
            guard !knownFiles.contains(item) else { continue }
            knownFiles.insert(item)

            let ext = (item as NSString).pathExtension.lowercased()
            guard Self.supportedExtensions.contains(ext) else { continue }

            // Skip optimized outputs
            if item.contains("_optimized") || item.contains("-optimized") { continue }

            let fileURL = dirURL.appendingPathComponent(item)

            do {
                let data = try Data(contentsOf: fileURL)
                let fileType = OptimizableFileType.from(data: data)

                let baseName = fileURL.deletingPathExtension().lastPathComponent

                if case .pdf = fileType {
                    let config = PDFOptimizer.PDFOptimizationConfig(
                        targetDPI: 150,
                        imageQuality: options.resolvedQuality(),
                        stripMetadata: options.stripMetadata
                    )
                    let (optimizedData, pdfResult) = try PDFOptimizer.shared.optimize(data: data, config: config)
                    guard pdfResult.optimizedSize < pdfResult.originalSize else { continue }

                    let outputURL = fileURL.deletingLastPathComponent()
                        .appendingPathComponent("\(baseName)_optimized.pdf")
                    if !options.dryRun {
                        try optimizedData.write(to: outputURL, options: .atomic)
                    }

                    let savings = String(format: "%.1f%%", pdfResult.savingsPercentage)
                    printResult(CLIResultJSON(
                        input: fileURL.path, inputSize: pdfResult.originalSize,
                        output: outputURL.path, outputSize: pdfResult.optimizedSize,
                        savings: savings, format: "pdf"
                    ), json: global.json, quiet: global.quiet)
                } else {
                    let config = options.buildConfig()
                    let (optimizedData, result) = try await ImageOptimizer.shared.optimize(data: data, config: config)
                    guard result.optimizedSize < result.originalSize else { continue }

                    let formatExt = result.format.fileExtension
                    let outputURL = fileURL.deletingLastPathComponent()
                        .appendingPathComponent("\(baseName)_optimized.\(formatExt)")
                    if !options.dryRun {
                        try optimizedData.write(to: outputURL, options: .atomic)
                    }

                    let savings = String(format: "%.1f%%", result.savingsPercentage)
                    printResult(CLIResultJSON(
                        input: fileURL.path, inputSize: result.originalSize,
                        output: outputURL.path, outputSize: result.optimizedSize,
                        savings: savings, format: result.format.rawValue
                    ), json: global.json, quiet: global.quiet)
                }
            } catch {
                if !global.quiet {
                    FileHandle.standardError.write(Data("Error: \(item): \(error.localizedDescription)\n".utf8))
                }
            }
        }
    }
}
