import SwiftUI
import AppKit

struct ComparisonSliderView: View {
    let originalData: Data
    let optimizedData: Data
    let maxWidth: CGFloat = 352

    @State private var sliderPosition: CGFloat = 0.5

    var body: some View {
        GeometryReader { geometry in
            let width = min(geometry.size.width, maxWidth)
            let height = width * 0.75

            ZStack {
                // Optimized (right side, shown as base)
                imageView(data: optimizedData)
                    .frame(width: width, height: height)
                    .clipped()

                // Original (left side, clipped by slider)
                imageView(data: originalData)
                    .frame(width: width, height: height)
                    .clipShape(
                        SliderClipShape(position: sliderPosition)
                    )

                // Slider line
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2, height: height)
                    .position(x: width * sliderPosition, y: height / 2)
                    .shadow(color: .black.opacity(0.5), radius: 2)

                // Slider handle
                Circle()
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
                    .shadow(color: .black.opacity(0.4), radius: 3)
                    .overlay(
                        HStack(spacing: 2) {
                            Image(systemName: "chevron.left")
                            Image(systemName: "chevron.right")
                        }
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(.gray)
                    )
                    .position(x: width * sliderPosition, y: height / 2)

                // Labels
                HStack {
                    Text("Original")
                        .font(VibeCheckTheme.Typography.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(4)
                    Spacer()
                    Text("Optimized")
                        .font(VibeCheckTheme.Typography.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(4)
                }
                .padding(.horizontal, 8)
                .frame(width: width)
                .position(x: width / 2, y: height - 16)
            }
            .frame(width: width, height: height)
            .cornerRadius(VibeCheckTheme.CornerRadius.sm)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        sliderPosition = min(max(value.location.x / width, 0), 1)
                    }
            )
        }
        .frame(height: maxWidth * 0.75)
    }

    private func imageView(data: Data) -> some View {
        Group {
            if let nsImage = downsampledImage(data: data, maxSide: Int(maxWidth * 2)) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.gray.opacity(0.3)
            }
        }
    }

    private func downsampledImage(data: Data, maxSide: Int) -> NSImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxSide,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }
}

private struct SliderClipShape: Shape {
    var position: CGFloat

    var animatableData: CGFloat {
        get { position }
        set { position = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(CGRect(x: 0, y: 0, width: rect.width * position, height: rect.height))
        return path
    }
}
