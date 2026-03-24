import SwiftUI

extension View {
  func shadow1() -> some View {
    self
      .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
      .shadow(color: .black.opacity(0.08), radius: 0.5, x: 0, y: 0)
  }

  func shadow2() -> some View {
    self
      .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
      .shadow(color: .black.opacity(0.08), radius: 0.5, x: 0, y: 0)
  }

  func shadow3() -> some View {
    self.shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 4)
      .shadow(color: .black.opacity(0.08), radius: 20.5, x: 0, y: 0)
  }
}
