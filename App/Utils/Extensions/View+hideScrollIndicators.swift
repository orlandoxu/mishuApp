import SwiftUI

extension View {
  @ViewBuilder
  func hideScrollIndicators() -> some View {
    if #available(iOS 16.0, *) {
      scrollIndicators(.hidden)
    } else {
      self
    }
  }
}
