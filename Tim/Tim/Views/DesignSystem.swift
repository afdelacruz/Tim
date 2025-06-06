import SwiftUI

// MARK: - Tim Design System
// Brand identity: Friendly, playful stick figure aesthetic
// Color scheme: Cream background (#FDFBD4) with black elements

struct TimColors {
    // Primary brand colors
    static let creamBackground = Color(hex: "#FFF9EB") // RGB: 255, 249, 235
    static let black = Color.black
    static let white = Color.white
    
    // Functional colors
    static let inflow = Color.green
    static let outflow = Color.red
    static let success = Color.green
    static let error = Color.red
    static let warning = Color.orange
    
    // Text colors
    static let primaryText = Color.black
    static let secondaryText = Color.black.opacity(0.7)
    static let placeholderText = Color.black.opacity(0.5)
}

struct TimTypography {
    // Font family - casual sans serif
    static let fontFamily = "System"
    
    // Font sizes
    static let largeTitle = Font.largeTitle.weight(.medium)
    static let title = Font.title.weight(.medium)
    static let title2 = Font.title2.weight(.medium)
    static let headline = Font.headline.weight(.medium)
    static let body = Font.body.weight(.regular)
    static let callout = Font.callout.weight(.regular)
    static let caption = Font.caption.weight(.regular)
    
    // Tim-specific styles
    static let timGreeting = Font.title.weight(.medium)
    static let widgetNumber = Font.title.weight(.bold)
    static let buttonText = Font.headline.weight(.medium)
}

struct TimSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

struct TimCornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
}

// MARK: - Tim Character Components

struct TimCharacter: View {
    let message: String
    let size: TimCharacterSize
    
    enum TimCharacterSize {
        case small, medium, large, extraLarge
        
        var dimensions: CGFloat {
            switch self {
            case .small: return 60
            case .medium: return 100
            case .large: return 140
            case .extraLarge: return 200
            }
        }
        
        var strokeWidth: CGFloat {
            switch self {
            case .small: return 2
            case .medium: return 3
            case .large: return 4
            case .extraLarge: return 5
            }
        }
    }
    
    var body: some View {
        VStack(spacing: TimSpacing.md) {
            // Speech bubble
            if !message.isEmpty {
                HStack {
                    Text(message)
                        .font(TimTypography.callout)
                        .foregroundColor(TimColors.primaryText)
                        .padding(TimSpacing.md)
                        .background(TimColors.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: TimCornerRadius.md)
                                .stroke(TimColors.black, lineWidth: 2)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: TimCornerRadius.md))
                    
                    Spacer()
                }
            }
            
            // Tim Character PNG
            Image("TimCharacter")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size.dimensions, height: size.dimensions)
        }
    }
}

// MARK: - Tim UI Components

struct TimButton: View {
    let title: String
    let action: () -> Void
    let style: TimButtonStyle
    
    enum TimButtonStyle {
        case primary, secondary, outline
        
        var backgroundColor: Color {
            switch self {
            case .primary: return TimColors.black
            case .secondary: return TimColors.white
            case .outline: return Color.clear
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary: return TimColors.white
            case .secondary: return TimColors.black
            case .outline: return TimColors.black
            }
        }
        
        var borderColor: Color {
            switch self {
            case .primary: return TimColors.black
            case .secondary: return TimColors.black
            case .outline: return TimColors.black
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(TimTypography.buttonText)
                .foregroundColor(style.foregroundColor)
                .padding(.horizontal, TimSpacing.lg)
                .padding(.vertical, TimSpacing.md)
                .background(style.backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: TimCornerRadius.md)
                        .stroke(style.borderColor, lineWidth: 2)
                )
                .clipShape(RoundedRectangle(cornerRadius: TimCornerRadius.md))
        }
    }
}

struct TimTextField: View {
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool
    
    init(_ placeholder: String, text: Binding<String>, isSecure: Bool = false) {
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
    }
    
    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .font(TimTypography.body)
        .foregroundColor(TimColors.primaryText)
        .padding(TimSpacing.md)
        .background(TimColors.white)
        .overlay(
            RoundedRectangle(cornerRadius: TimCornerRadius.md)
                .stroke(TimColors.black, lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: TimCornerRadius.md))
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
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Tim Background Modifier

struct TimBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(TimColors.creamBackground)
    }
}

extension View {
    func timBackground() -> some View {
        modifier(TimBackground())
    }
} 