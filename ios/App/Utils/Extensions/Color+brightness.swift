import SwiftUI

extension Color {
  /// 调整 `Color` 的亮度
  /// - Parameter amount: 亮度变化范围 `-1.0 ~ 1.0`（负值变暗，正值变亮）
  /// - Returns: 变更亮度后的 `Color`
  func brightness(_ amount: CGFloat) -> Color {
    let uiColor = UIColor(self)  // 将 `Color` 转换为 `UIColor`
    var hue: CGFloat = 0
    var saturation: CGFloat = 0
    var brightness: CGFloat = 0
    var alpha: CGFloat = 0

    if uiColor.getHue(
      &hue,
      saturation: &saturation,
      brightness: &brightness,
      alpha: &alpha
    ) {
      return Color(
        hue: hue,
        saturation: saturation,
        brightness: max(min(brightness + amount, 1.0), 0.0),
        opacity: Double(alpha)
      )
    }

    return self  // 如果转换失败，返回原色
  }
}
