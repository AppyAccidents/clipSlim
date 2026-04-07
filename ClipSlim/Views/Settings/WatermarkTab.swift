import SwiftUI

struct WatermarkTab: View {

    @Environment(AppViewModel.self) private var viewModel

    private var settings: AppSettings { viewModel.settings }

    @State private var previewData: Data?
    @State private var previewTask: Task<Void, Never>?

    var body: some View {
        VibeSettingsPage {
            // Card 1: Enable + Type
            VibeSettingsCard(title: "Watermark", icon: "drop.halffull") {
                Toggle("Enable watermark", isOn: watermarkEnabledBinding)
                VibeHintText(text: "Apply a text or image watermark to optimized images.")

                if currentConfig.enabled {
                    Picker("Type", selection: watermarkTypeBinding) {
                        Text("Text").tag(WatermarkType.text)
                        Text("Image").tag(WatermarkType.image)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
            }

            // Card 2: Text Settings
            if currentConfig.enabled && currentConfig.type == .text {
                VibeSettingsCard(title: "Text Settings", icon: "textformat") {
                    HStack {
                        Text("Text")
                            .font(VibeCheckTheme.Typography.body)
                            .foregroundColor(VibeCheckTheme.Colors.textSecondary)
                        Spacer()
                        TextField("Watermark text", text: watermarkTextBinding)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 200)
                            .font(VibeCheckTheme.Typography.body)
                    }

                    HStack {
                        Text("Font")
                            .font(VibeCheckTheme.Typography.body)
                            .foregroundColor(VibeCheckTheme.Colors.textSecondary)
                        Spacer()
                        Picker("Font", selection: watermarkFontBinding) {
                            ForEach(availableFonts, id: \.self) { fontName in
                                Text(fontName)
                                    .font(.custom(fontName, size: 12))
                                    .tag(fontName)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 200)
                    }

                    HStack {
                        Text("Size")
                            .font(VibeCheckTheme.Typography.body)
                            .foregroundColor(VibeCheckTheme.Colors.textSecondary)
                        Text("\(Int(currentConfig.fontSize)) pt")
                            .font(VibeCheckTheme.Typography.monospacedFont)
                            .frame(width: 50, alignment: .leading)
                        Slider(value: fontSizeBinding, in: 8...120, step: 1)
                    }

                    HStack {
                        Text("Color")
                            .font(VibeCheckTheme.Typography.body)
                            .foregroundColor(VibeCheckTheme.Colors.textSecondary)
                        Spacer()
                        ColorPicker("", selection: colorBinding, supportsOpacity: true)
                            .labelsHidden()
                    }

                    VibeHintText(text: "Font size is in points. Use the color picker to set opacity.")
                }
            }

            // Card 3: Image Settings
            if currentConfig.enabled && currentConfig.type == .image {
                VibeSettingsCard(title: "Image Settings", icon: "photo") {
                    HStack {
                        Text("Image")
                            .font(VibeCheckTheme.Typography.body)
                            .foregroundColor(VibeCheckTheme.Colors.textSecondary)
                        Spacer()
                        if !currentConfig.imagePath.isEmpty {
                            Text(URL(fileURLWithPath: currentConfig.imagePath).lastPathComponent)
                                .font(VibeCheckTheme.Typography.caption)
                                .foregroundColor(VibeCheckTheme.Colors.textSecondary)
                                .lineLimit(1)
                        }
                        Button("Choose...") {
                            chooseWatermarkImage()
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(VibeCheckTheme.Colors.neonCyan)
                    }

                    HStack {
                        Text("Opacity")
                            .font(VibeCheckTheme.Typography.body)
                            .foregroundColor(VibeCheckTheme.Colors.textSecondary)
                        Text("\(Int(currentConfig.imageOpacity * 100))%")
                            .font(VibeCheckTheme.Typography.monospacedFont)
                            .frame(width: 50, alignment: .leading)
                        Slider(value: imageOpacityBinding, in: 0.05...1.0, step: 0.05)
                    }

                    VibeHintText(text: "Choose a PNG with transparency for best results.")
                }
            }

            // Card 4: Position (9-grid)
            if currentConfig.enabled {
                VibeSettingsCard(title: "Position", icon: "square.grid.3x3") {
                    positionGrid
                    VibeHintText(text: "Select where the watermark is placed on the image.")

                    HStack {
                        Text("Margin")
                            .font(VibeCheckTheme.Typography.body)
                            .foregroundColor(VibeCheckTheme.Colors.textSecondary)
                        Text("\(Int(currentConfig.margin)) px")
                            .font(VibeCheckTheme.Typography.monospacedFont)
                            .frame(width: 60, alignment: .leading)
                        Slider(value: marginBinding, in: 0...100, step: 5)
                    }
                }
            }

            // Card 5: Tiling
            if currentConfig.enabled {
                VibeSettingsCard(title: "Tiling", icon: "square.grid.3x3.fill") {
                    Toggle("Enable tiling", isOn: tilingEnabledBinding)
                    VibeHintText(text: "Repeat the watermark across the entire image.")

                    if currentConfig.tilingEnabled {
                        HStack {
                            Text("Spacing")
                                .font(VibeCheckTheme.Typography.body)
                                .foregroundColor(VibeCheckTheme.Colors.textSecondary)
                            Text("\(Int(currentConfig.tilingSpacing)) px")
                                .font(VibeCheckTheme.Typography.monospacedFont)
                                .frame(width: 60, alignment: .leading)
                            Slider(value: tilingSpacingBinding, in: 20...400, step: 10)
                        }
                    }
                }
            }

            // Card 6: Preview
            if currentConfig.enabled {
                VibeSettingsCard(title: "Preview", icon: "eye") {
                    previewView
                    VibeHintText(text: "Live preview of the watermark on a sample image.")
                }
            }
        }
        .onChange(of: currentConfig) { _, _ in
            schedulePreviewUpdate()
        }
        .onAppear {
            schedulePreviewUpdate()
        }
    }

    // MARK: - Position Grid

    private var positionGrid: some View {
        let positions: [[WatermarkPosition]] = [
            [.topLeft, .topCenter, .topRight],
            [.middleLeft, .center, .middleRight],
            [.bottomLeft, .bottomCenter, .bottomRight]
        ]

        return VStack(spacing: VibeCheckTheme.Spacing.xs) {
            ForEach(positions, id: \.self) { row in
                HStack(spacing: VibeCheckTheme.Spacing.xs) {
                    ForEach(row, id: \.self) { position in
                        positionButton(position)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func positionButton(_ position: WatermarkPosition) -> some View {
        let isSelected = currentConfig.position == position
        return Button {
            var config = currentConfig
            config.position = position
            saveConfig(config)
        } label: {
            RoundedRectangle(cornerRadius: VibeCheckTheme.CornerRadius.sm)
                .fill(isSelected ? VibeCheckTheme.Colors.neonCyan.opacity(0.2) : VibeCheckTheme.Colors.surface)
                .frame(width: 40, height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: VibeCheckTheme.CornerRadius.sm)
                        .stroke(isSelected ? VibeCheckTheme.Colors.neonCyan : VibeCheckTheme.Colors.border, lineWidth: isSelected ? 2 : 1)
                )
                .overlay(
                    Circle()
                        .fill(isSelected ? VibeCheckTheme.Colors.neonCyan : VibeCheckTheme.Colors.textTertiary)
                        .frame(width: 8, height: 8)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Preview

    private var previewView: some View {
        Group {
            if let previewData,
               let nsImage = NSImage(data: previewData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 256, maxHeight: 256)
                    .cornerRadius(VibeCheckTheme.CornerRadius.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: VibeCheckTheme.CornerRadius.sm)
                            .stroke(VibeCheckTheme.Colors.border, lineWidth: 1)
                    )
                    .frame(maxWidth: .infinity)
            } else {
                Text("No preview available")
                    .font(VibeCheckTheme.Typography.caption)
                    .foregroundColor(VibeCheckTheme.Colors.textTertiary)
                    .frame(maxWidth: .infinity, minHeight: 128)
            }
        }
    }

    private func schedulePreviewUpdate() {
        previewTask?.cancel()
        previewTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            let config = currentConfig
            guard config.enabled else {
                previewData = nil
                return
            }
            let sampleImage = makeSampleImage()
            guard let sampleImage else { return }
            let result = try? WatermarkService.shared.apply(to: sampleImage, config: config)
            if !Task.isCancelled {
                previewData = result
            }
        }
    }

    private func makeSampleImage() -> Data? {
        let size = 256
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let context = CGContext(
            data: nil, width: size, height: size,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: colorSpace, bitmapInfo: bitmapInfo.rawValue
        ) else { return nil }

        // Gradient-ish background
        context.setFillColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1.0)
        context.fill(CGRect(x: 0, y: 0, width: size, height: size))
        context.setFillColor(red: 0.3, green: 0.5, blue: 0.7, alpha: 0.5)
        context.fillEllipse(in: CGRect(x: 30, y: 30, width: size - 60, height: size - 60))

        guard let image = context.makeImage() else { return nil }
        let mutableData = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(
            mutableData as CFMutableData, "public.png" as CFString, 1, nil
        ) else { return nil }
        CGImageDestinationAddImage(dest, image, nil)
        guard CGImageDestinationFinalize(dest) else { return nil }
        return mutableData as Data
    }

    // MARK: - File Picker

    private func chooseWatermarkImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .tiff]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.begin { response in
            if response == .OK, let url = panel.url {
                var config = currentConfig
                config.imagePath = url.path
                saveConfig(config)
            }
        }
    }

    // MARK: - Config Access

    private var currentConfig: WatermarkConfig {
        settings.currentWatermarkConfig
    }

    private func saveConfig(_ config: WatermarkConfig) {
        settings.currentWatermarkConfig = config
    }

    // MARK: - System Fonts

    private var availableFonts: [String] {
        NSFontManager.shared.availableFontFamilies.sorted()
    }

    // MARK: - Bindings

    private var watermarkEnabledBinding: Binding<Bool> {
        Binding(
            get: { currentConfig.enabled },
            set: { newValue in
                var config = currentConfig
                config.enabled = newValue
                saveConfig(config)
            }
        )
    }

    private var watermarkTypeBinding: Binding<WatermarkType> {
        Binding(
            get: { currentConfig.type },
            set: { newValue in
                var config = currentConfig
                config.type = newValue
                saveConfig(config)
            }
        )
    }

    private var watermarkTextBinding: Binding<String> {
        Binding(
            get: { currentConfig.text },
            set: { newValue in
                var config = currentConfig
                config.text = newValue
                saveConfig(config)
            }
        )
    }

    private var watermarkFontBinding: Binding<String> {
        Binding(
            get: { currentConfig.fontName },
            set: { newValue in
                var config = currentConfig
                config.fontName = newValue
                saveConfig(config)
            }
        )
    }

    private var fontSizeBinding: Binding<CGFloat> {
        Binding(
            get: { currentConfig.fontSize },
            set: { newValue in
                var config = currentConfig
                config.fontSize = newValue
                saveConfig(config)
            }
        )
    }

    private var colorBinding: Binding<Color> {
        Binding(
            get: {
                let c = currentConfig.color
                return Color(red: c.red, green: c.green, blue: c.blue, opacity: c.alpha)
            },
            set: { newColor in
                var config = currentConfig
                let nsColor = NSColor(newColor).usingColorSpace(.deviceRGB) ?? NSColor.white
                config.color = CodableColor(
                    red: CGFloat(nsColor.redComponent),
                    green: CGFloat(nsColor.greenComponent),
                    blue: CGFloat(nsColor.blueComponent),
                    alpha: CGFloat(nsColor.alphaComponent)
                )
                saveConfig(config)
            }
        )
    }

    private var imageOpacityBinding: Binding<CGFloat> {
        Binding(
            get: { currentConfig.imageOpacity },
            set: { newValue in
                var config = currentConfig
                config.imageOpacity = newValue
                saveConfig(config)
            }
        )
    }

    private var marginBinding: Binding<CGFloat> {
        Binding(
            get: { currentConfig.margin },
            set: { newValue in
                var config = currentConfig
                config.margin = newValue
                saveConfig(config)
            }
        )
    }

    private var tilingEnabledBinding: Binding<Bool> {
        Binding(
            get: { currentConfig.tilingEnabled },
            set: { newValue in
                var config = currentConfig
                config.tilingEnabled = newValue
                saveConfig(config)
            }
        )
    }

    private var tilingSpacingBinding: Binding<CGFloat> {
        Binding(
            get: { currentConfig.tilingSpacing },
            set: { newValue in
                var config = currentConfig
                config.tilingSpacing = newValue
                saveConfig(config)
            }
        )
    }
}
