import SwiftUI

struct FullBrandButtonModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .font(.system(size: 16, weight: .medium))
      .foregroundColor(.white)
      .frame(maxWidth: .infinity)
      .frame(height: 48)
      .background(Color(hex: "0x06BAFF"))
      .cornerRadius(24)
  }
}

extension View {
  func FullBrandButton() -> some View {
    modifier(FullBrandButtonModifier())
  }
}
