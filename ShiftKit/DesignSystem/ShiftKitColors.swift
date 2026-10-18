import SwiftUI
import AppKit

// MARK: - ShiftKit Brand Palette
/// Defines the strict light-only, warm artisanal color palette for ShiftKit.
/// Note: Purple and Blue are strictly forbidden per product design guidelines.
public enum ShiftKitColors {
    // Exact requested color specifications
    public static let warmIvory      = Color(hex: 0xFAF8F3)
    public static let softCream      = Color(hex: 0xF3EEE4)
    public static let pureWhite      = Color(hex: 0xFFFFFF)
    public static let mutedSage      = Color(hex: 0xA8B5A0)
    public static let deepOlive      = Color(hex: 0x465343)
    public static let softTerracotta = Color(hex: 0xD98768)
    public static let warmPeach      = Color(hex: 0xF5D5C2)
    public static let sandBeige      = Color(hex: 0xE5D8C7)
    public static let charcoalBrown  = Color(hex: 0x34312D)

    // Semantic roles (Light Theme Only)
    public static let background        = warmIvory
    public static let surface           = pureWhite
    public static let surfaceSecondary  = softCream
    public static let border            = sandBeige
    public static let borderSubtle      = sandBeige.opacity(0.6)

    public static let textPrimary       = charcoalBrown
    public static let textSecondary     = deepOlive.opacity(0.8)
    public static let textMuted         = charcoalBrown.opacity(0.55)

    public static let accentPrimary     = softTerracotta
    public static let accentSecondary   = mutedSage
    public static let accentHover       = warmPeach

    public static let statusSuccess     = mutedSage
    public static let statusWarning     = softTerracotta
    public static let statusNeutral     = sandBeige

    // AppKit counterparts for native window controls
    public enum NS {
        public static let warmIvory      = NSColor(hex: 0xFAF8F3)
        public static let softCream      = NSColor(hex: 0xF3EEE4)
        public static let pureWhite      = NSColor(hex: 0xFFFFFF)
        public static let mutedSage      = NSColor(hex: 0xA8B5A0)
        public static let deepOlive      = NSColor(hex: 0x465343)
        public static let softTerracotta = NSColor(hex: 0xD98768)
        public static let warmPeach      = NSColor(hex: 0xF5D5C2)
        public static let sandBeige      = NSColor(hex: 0xE5D8C7)
        public static let charcoalBrown  = NSColor(hex: 0x34312D)
    }
}

// MARK: - Color Extension for Hex Initialization
extension Color {
    public init(hex: UInt32, alpha: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }

    public init(hex hexString: String, alpha: Double = 1.0) {
        let clean = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&int)
        self.init(hex: UInt32(int), alpha: alpha)
    }
}

extension NSColor {
    public convenience init(hex: UInt32, alpha: CGFloat = 1.0) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255.0
        let green = CGFloat((hex >> 8) & 0xFF) / 255.0
        let blue = CGFloat(hex & 0xFF) / 255.0
        self.init(srgbRed: red, green: green, blue: blue, alpha: alpha)
    }

    public convenience init(hex hexString: String, alpha: CGFloat = 1.0) {
        let clean = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&int)
        self.init(hex: UInt32(int), alpha: alpha)
    }
}
