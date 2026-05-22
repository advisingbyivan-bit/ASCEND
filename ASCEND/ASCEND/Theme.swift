import SwiftUI

extension Color {
    static let ascendCyan = Color(red: 0, green: 217/255, blue: 1)           // #00D9FF
    static let ascendPurple = Color(red: 157/255, green: 78/255, blue: 221/255) // #9D4EDD
    static let ascendGreen = Color(red: 57/255, green: 1, blue: 20/255)       // #39FF14
    static let ascendRed = Color(red: 1, green: 23/255, blue: 68/255)         // #FF1744
    static let ascendYellow = Color(red: 1, green: 193/255, blue: 7/255)      // #FFC107
    static let ascendNavy = Color(red: 10/255, green: 14/255, blue: 39/255)   // #0A0E27
    static let ascendCharcoal = Color(red: 31/255, green: 41/255, blue: 55/255) // #1F2937
    static let ascendTextSecondary = Color(red: 156/255, green: 163/255, blue: 175/255) // #9CA3AF
}

extension ShapeStyle where Self == Color {
    static var ascendBackground: Color { .ascendNavy }
}
