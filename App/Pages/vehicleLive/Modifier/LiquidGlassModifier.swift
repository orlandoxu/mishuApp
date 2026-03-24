import SwiftUI

// MARK: - LiquidGlassModifier

/// 液态玻璃效果 Modifier
/// - iOS 26+: 使用系统原生 glassEffect
/// - iOS 14-25: 使用半透明渐变模拟
private struct LiquidGlassModifier: ViewModifier {
  let highlight: Bool

  func body(content: Content) -> some View {
    if #available(iOS 26.0, *) {
      let tint = highlight ? ThemeColor.brand500.opacity(0.2) : Color.clear
      content.glassEffect(.clear.tint(tint).interactive(), in: Circle())
    } else {
      content.backdropGlassEffect()
    }
  }
}

extension View {
  /// 液态玻璃效果
  func glass4FuncBtn(highlight: Bool = false) -> some View {
    modifier(LiquidGlassModifier(highlight: highlight))
  }

  /// iOS 14-25 的退化方案
  func backdropGlassEffect() -> some View {
    background(
      Capsule()
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
      Capsule()
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

  /// Picker 轨道液态玻璃效果
  @ViewBuilder
  func glass4PickerTrack() -> some View {
    if #available(iOS 26.0, *) {
      glassEffect(.clear.tint(Color.clear), in: Capsule())
    } else {
      overlay(
        Capsule().stroke(Color.white.opacity(0.28), lineWidth: 1)
      )
      .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
    }
  }

  /// Picker 滑块液态玻璃效果
  @ViewBuilder
  func glass4PickerThumb() -> some View {
    if #available(iOS 26.0, *) {
      glassEffect(.clear.tint(Color.white.opacity(0.22)).interactive(), in: Capsule())
    } else {
      overlay(
        Capsule()
          .stroke(Color.white.opacity(0.55), lineWidth: 1)
      )
    }
  }
}
