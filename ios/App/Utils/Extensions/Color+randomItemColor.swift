import SwiftUI

extension Color {
  static func randomItemColor() -> String {
    return ["item1", "item2", "item3", "item4", "item5"].randomElement()
      ?? "item1"
  }
}
