import SwiftUI

/// 未读红点 Modifier
/// 叠加在任意 View 的右上角
struct UnreadBadge: ViewModifier {
  /// 是否显示红点
  let isShown: Bool

  func body(content: Content) -> some View {
    ZStack(alignment: .topTrailing) {
      content
      if isShown {
        Circle()
          .fill(Color.red)
          .frame(width: 8, height: 8)
          .offset(x: -8, y: 8)
      }
    }
  }
}

extension View {
  /// 添加未读红点
  /// - Parameter isShown: 是否显示红点
  /// - Returns: 叠加红点后的 View
  func unreadBadge(_ isShown: Bool) -> some View {
    modifier(UnreadBadge(isShown: isShown))
  }
}
