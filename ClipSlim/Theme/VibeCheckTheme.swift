import SwiftUI

enum VibeCheckTheme {
    
    // MARK: - Colors
    enum Colors {
        static let background = Color(hex: "0a0e14")
        static let surface = Color(hex: "151a21")
        static let surfaceElevated = Color(hex: "1f2630")
        
        static let neonCyan = Color(hex: "00ffff")
        static let neonOrange = Color(hex: "ff6b35")
        static let neonPurple = Color(hex: "b877ff")
        
        static let textPrimary = Color(hex: "e6e8eb")
        static let textSecondary = Color(hex: "8a8f98")
        static let textTertiary = Color(hex: "5c6370")
        
        static let success = Color(hex: "00ff88")
        static let warning = Color(hex: "ffaa00")
        static let error = Color(hex: "ff3366")
        
        static let border = Color(hex: "2a3038")
        static let borderActive = neonCyan
    }
    
    // MARK: - Typography
    enum Typography {
        static let monospacedFont = Font.system(.body, design: .monospaced)
        static let monospacedBold = Font.system(.body, design: .monospaced).weight(.bold)
        
        static let title = Font.system(size: 18, weight: .bold, design: .monospaced)
        static let headline = Font.system(size: 14, weight: .semibold, design: .monospaced)
        static let body = Font.system(size: 13, design: .monospaced)
        static let caption = Font.system(size: 11, design: .monospaced)
        static let tiny = Font.system(size: 9, design: .monospaced)
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
    
    // MARK: - Corner Radius
    enum CornerRadius {
        static let sm: CGFloat = 4
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
    }
    
    // MARK: - Glow Effects
    static func neonGlow(color: Color, radius: CGFloat = 8) -> some View {
        EmptyView()
            .shadow(color: color.opacity(0.6), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.3), radius: radius * 2, x: 0, y: 0)
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
            .shadow(color: VibeCheckTheme.Colors.neonCyan.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    func neonGlow(color: Color = VibeCheckTheme.Colors.neonCyan, radius: CGFloat = 8) -> some View {
        self
            .shadow(color: color.opacity(0.6), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.3), radius: radius * 2, x: 0, y: 0)
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
        
        var backgroundColor: Color {
            switch self {
            case .primary: return VibeCheckTheme.Colors.neonCyan
            case .secondary: return VibeCheckTheme.Colors.surface
            case .danger: return VibeCheckTheme.Colors.error
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary: return VibeCheckTheme.Colors.background
            case .secondary: return VibeCheckTheme.Colors.neonCyan
            case .danger: return VibeCheckTheme.Colors.textPrimary
            }
        }
        
        var glowColor: Color? {
            switch self {
            case .primary: return VibeCheckTheme.Colors.neonCyan
            case .secondary: return nil
            case .danger: return VibeCheckTheme.Colors.error
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
