import SwiftUI

extension View {
  /// 为图标添加旋转动画效果
  /// - Parameter isExpanded: 是否展开
  /// - Returns: 添加了旋转动画效果的视图
  func rotationIcon(isExpanded: Bool) -> some View {
    self
      .rotationEffect(.degrees(isExpanded ? 90 : 0))
      .animation(.easeInOut(duration: 0.3), value: isExpanded)
  }
}
