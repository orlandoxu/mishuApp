import SwiftUI

extension Color {
  init(hex: String) {
    var cleaned = hex
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .replacingOccurrences(of: "#", with: "")
    if cleaned.lowercased().hasPrefix("0x") {
      cleaned = String(cleaned.dropFirst(2))
    }
    let value = UInt64(cleaned, radix: 16) ?? 0
    let r = Double((value >> 16) & 0xFF) / 255.0
    let g = Double((value >> 8) & 0xFF) / 255.0
    let b = Double(value & 0xFF) / 255.0
    self.init(red: r, green: g, blue: b)
  }

  init(_ hex: String) {
    var hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    if hex.lowercased().hasPrefix("0x") {
      hex = String(hex.dropFirst(2))
    }
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let a: UInt64
    let r: UInt64
    let g: UInt64
    let b: UInt64
    switch hex.count {
    case 3: // RGB (12-bit)
      (a, r, g, b) = (
        255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17
      )
    case 6: // RGB (24-bit)
      (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8: // ARGB (32-bit)
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
