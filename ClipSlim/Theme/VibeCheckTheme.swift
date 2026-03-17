import SwiftUI

enum VibeCheckTheme {
    
    // MARK: - Colors (AppyAccidents Design Language)
    enum Colors {
        // Background layers
        static let backgroundPrimary = Color(hex: "0D0D0F")
        static let backgroundSecondary = Color(hex: "161619")
        static let backgroundCard = Color(hex: "1C1C21")
        static let backgroundElevated = Color(hex: "232329")
        
        // Legacy aliases for compatibility
        static let background = backgroundPrimary
        static let surface = backgroundCard
        static let surfaceElevated = backgroundElevated
        
        // Accent colors
        static let neonCyan = Color(hex: "00F5FF")
        static let neonOrange = Color(hex: "FF8A00")
        
        // Status colors (semantic)
        static let statusOk = Color(hex: "00F5FF")
        static let statusWarning = Color(hex: "FF8A00")
        static let statusOver = Color(hex: "FF5A1F")
        static let statusStale = Color(hex: "6B6B7A")
        static let statusAuth = Color(hex: "FF8A00")
        
        // Legacy status aliases
        static let success = statusOk
        static let warning = statusWarning
        static let error = statusOver
        
        // Text colors
        static let textPrimary = Color(hex: "FAFAFA")
        static let textSecondary = Color(hex: "A0A0B0")
        static let textTertiary = Color(hex: "8080A0")

        // Structural
        static let border = Color.white.opacity(0.12)
        static let borderActive = neonCyan
    }
    
    // MARK: - Typography
    enum Typography {
        static let monospacedFont = Font.system(.body, design: .monospaced)
        static let monospacedBold = Font.system(.body, design: .monospaced).weight(.bold)
        
        // Heading sizes (16-20 for section headers)
        static let title = Font.system(size: 18, weight: .bold, design: .monospaced)
        static let headline = Font.system(size: 14, weight: .semibold, design: .monospaced)
        
        // Body and label sizes (12-14 for UI labels and controls)
        static let body = Font.system(size: 13, design: .monospaced)
        static let caption = Font.system(size: 11, design: .monospaced)
        
        // Metric sizes (for numbers and percentages)
        static let metric = Font.system(size: 22, weight: .bold, design: .monospaced)
        static let metricLarge = Font.system(size: 28, weight: .bold, design: .monospaced)
        
        // Minimum size per design doc (10-12 for badges, micro labels)
        static let tiny = Font.system(size: 10, design: .monospaced)
    }
    
    // MARK: - Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }
    
    // MARK: - Corner Radius (AppyAccidents Design Language)
    enum CornerRadius {
        static let sm: CGFloat = 6
        static let md: CGFloat = 10
        static let lg: CGFloat = 14
        static let xl: CGFloat = 20
    }
    
    // MARK: - Glow Effects (simplified for performance)
    static func neonGlow(color: Color, radius: CGFloat = 6) -> some View {
        EmptyView()
            .shadow(color: color.opacity(0.5), radius: radius, x: 0, y: 0)
    }
}

// MARK: - View Modifiers
extension View {
    func vibeCard() -> some View {
        self
            .background(VibeCheckTheme.Colors.surface)
            .cornerRadius(VibeCheckTheme.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: VibeCheckTheme.CornerRadius.md)
                    .stroke(VibeCheckTheme.Colors.border, lineWidth: 1)
            )
    }
    
    func vibeCardElevated() -> some View {
        self
            .background(VibeCheckTheme.Colors.surfaceElevated)
            .cornerRadius(VibeCheckTheme.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: VibeCheckTheme.CornerRadius.md)
                    .stroke(VibeCheckTheme.Colors.borderActive.opacity(0.3), lineWidth: 1)
            )
    }
    
    /// Simplified single-shadow glow for performance (background app optimization)
    func neonGlow(color: Color = VibeCheckTheme.Colors.neonCyan, radius: CGFloat = 6) -> some View {
        self
            .shadow(color: color.opacity(0.5), radius: radius, x: 0, y: 0)
    }
}

// MARK: - Reusable Components
struct VibeButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let action: () -> Void
    
    enum ButtonStyle {
        case primary
        case secondary
        case danger
        case donation

        var backgroundColor: Color {
            switch self {
            case .primary: return VibeCheckTheme.Colors.neonCyan
            case .secondary: return VibeCheckTheme.Colors.surface
            case .danger: return VibeCheckTheme.Colors.error
            case .donation: return VibeCheckTheme.Colors.neonOrange
            }
        }

        var foregroundColor: Color {
            switch self {
            case .primary: return VibeCheckTheme.Colors.background
            case .secondary: return VibeCheckTheme.Colors.neonCyan
            case .danger: return VibeCheckTheme.Colors.textPrimary
            case .donation: return VibeCheckTheme.Colors.backgroundPrimary
            }
        }

        var glowColor: Color? {
            switch self {
            case .primary: return VibeCheckTheme.Colors.neonCyan
            case .secondary: return nil
            case .danger: return VibeCheckTheme.Colors.error
            case .donation: return VibeCheckTheme.Colors.neonOrange
            }
        }
    }
    
    init(_ title: String, icon: String? = nil, style: ButtonStyle = .primary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: VibeCheckTheme.Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .font(VibeCheckTheme.Typography.body)
            }
            .foregroundColor(style.foregroundColor)
            .padding(.horizontal, VibeCheckTheme.Spacing.md)
            .padding(.vertical, VibeCheckTheme.Spacing.sm)
            .background(style.backgroundColor)
            .cornerRadius(VibeCheckTheme.CornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: VibeCheckTheme.CornerRadius.sm)
                    .stroke(style == .secondary ? VibeCheckTheme.Colors.neonCyan : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .if(style.glowColor != nil) { view in
            view.neonGlow(color: style.glowColor!)
        }
    }
}

struct VibeDivider: View {
    var body: some View {
        Rectangle()
            .fill(VibeCheckTheme.Colors.border)
            .frame(height: 1)
    }
}

struct VibeLabel: View {
    let title: String
    let value: String
    let valueColor: Color
    
    init(_ title: String, value: String, valueColor: Color = VibeCheckTheme.Colors.textPrimary) {
        self.title = title
        self.value = value
        self.valueColor = valueColor
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(VibeCheckTheme.Typography.body)
                .foregroundColor(VibeCheckTheme.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(VibeCheckTheme.Typography.monospacedBold)
                .foregroundColor(valueColor)
        }
    }
}

// MARK: - Helper Extensions
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
