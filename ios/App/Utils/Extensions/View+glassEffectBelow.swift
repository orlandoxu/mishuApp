import SwiftUI

// MARK: - 液态玻璃效果插件

extension View {
  func backdropGlassEffect<S: Shape>(shape: S) -> some View {
    background(
      shape
        .fill(
          LinearGradient(
            colors: [
              Color.white.opacity(0.35),
              Color.white.opacity(0.12),
            ],
            startPoint: .top,
            endPoint: .bottom
          )
        )
    )
    .overlay(
      shape
        .stroke(
          LinearGradient(
            colors: [
              Color.white.opacity(0.5),
              Color.white.opacity(0.15),
            ],
            startPoint: .top,
            endPoint: .bottom
          ),
          lineWidth: 1
        )
    )
    .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
  }
}
