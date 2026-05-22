import SwiftUI

public extension Color {
    static let ds_cyan = Color(red: 0, green: 217.0/255, blue: 1)
    static let ds_purple = Color(red: 157.0/255, green: 78.0/255, blue: 221.0/255)
    static let ds_green = Color(red: 57.0/255, green: 1, blue: 20.0/255)
    static let ds_red = Color(red: 1, green: 23.0/255, blue: 68.0/255)
    static let ds_yellow = Color(red: 1, green: 193.0/255, blue: 7.0/255)
    static let ds_navy = Color(red: 10.0/255, green: 14.0/255, blue: 39.0/255)
    static let ds_charcoal = Color(red: 31.0/255, green: 41.0/255, blue: 55.0/255)
    static let ds_cardBorder = Color.white.opacity(0.08)
    static let ds_textPrimary = Color.white
    static let ds_textSecondary = Color(red: 156.0/255, green: 163.0/255, blue: 175.0/255)
    static let ds_gold = Color(red: 1, green: 215.0/255, blue: 0)
}

public extension ShapeStyle where Self == Color {
    static var ds_background: Color { .ds_navy }
}
