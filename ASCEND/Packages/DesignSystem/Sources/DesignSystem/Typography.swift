import SwiftUI

public enum DSFont {
    public static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    public static func mono(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    public static let heroTitle = Font.system(size: 34, weight: .black, design: .default)
    public static let screenTitle = Font.system(size: 28, weight: .bold, design: .default)
    public static let sectionTitle = Font.system(size: 20, weight: .semibold, design: .default)
    public static let cardTitle = Font.system(size: 17, weight: .semibold, design: .default)
    public static let body = Font.system(size: 15, weight: .regular, design: .default)
    public static let bodyBold = Font.system(size: 15, weight: .semibold, design: .default)
    public static let caption = Font.system(size: 13, weight: .regular, design: .default)
    public static let captionBold = Font.system(size: 13, weight: .semibold, design: .default)
    public static let stat = Font.system(size: 24, weight: .bold, design: .monospaced)
    public static let statSmall = Font.system(size: 17, weight: .semibold, design: .monospaced)
    public static let micro = Font.system(size: 11, weight: .medium, design: .default)
}

public extension Text {
    func dsStyle(_ font: Font, color: Color = .ds_textPrimary) -> Text {
        self.font(font).foregroundColor(color)
    }
}
