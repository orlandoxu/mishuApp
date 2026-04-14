import SwiftUI

// MARK: - CSS Style Padding
extension View {
  /// CSS 风格的 padding，使用一个值
  /// - Parameter value: 所有方向的 padding 值
  /// - Returns: 应用了 padding 的视图
  func cssPadding(_ value: CGFloat) -> some View {
    cssPadding(value, value, value, value)
  }

  /// CSS 风格的 padding，使用两个值
  /// - Parameters:
  ///   - vertical: 上下方向的 padding 值
  ///   - horizontal: 左右方向的 padding 值
  /// - Returns: 应用了 padding 的视图
  func cssPadding(_ vertical: CGFloat, _ horizontal: CGFloat) -> some View {
    cssPadding(vertical, horizontal, vertical, horizontal)
  }

  /// CSS 风格的 padding，使用三个值
  /// - Parameters:
  ///   - top: 上方向的 padding 值
  ///   - horizontal: 左右方向的 padding 值
  ///   - bottom: 下方向的 padding 值
  /// - Returns: 应用了 padding 的视图
  func cssPadding(_ top: CGFloat, _ horizontal: CGFloat, _ bottom: CGFloat)
    -> some View {
    cssPadding(top, horizontal, bottom, horizontal)
  }

  /// CSS 风格的 padding，使用四个值
  /// - Parameters:
  ///   - top: 上方向的 padding 值
  ///   - trailing: 右方向的 padding 值
  ///   - bottom: 下方向的 padding 值
  ///   - leading: 左方向的 padding 值
  /// - Returns: 应用了 padding 的视图
  func cssPadding(
    _ top: CGFloat,
    _ trailing: CGFloat,
    _ bottom: CGFloat,
    _ leading: CGFloat
  ) -> some View {
    padding(
      EdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing)
    )
  }

  /// CSS 风格的 padding，使用 EdgeInsets
  /// - Parameter insets: EdgeInsets 对象
  /// - Returns: 应用了 padding 的视图
  func cssPadding(_ insets: EdgeInsets) -> some View {
    padding(
      .top,
      insets.top
    )
    .padding(.trailing, insets.trailing)
    .padding(.bottom, insets.bottom)
    .padding(.leading, insets.leading)
  }

  /// 条件修饰符
  /// - Parameters:
  ///   - condition: 条件
  ///   - transform: 满足条件时应用的转换
  /// - Returns: 转换后的视图
  @ViewBuilder func `if`<Content: View>(
    _ condition: Bool,
    transform: (Self) -> Content
  ) -> some View {
    if condition {
      transform(self)
    } else {
      self
    }
  }
}

// MARK: - Preview
#Preview {
  VStack {
    // 一个值：所有方向都是 20
    Text("cssPadding(20)")
      .cssPadding(20)
      .background(Color.red.opacity(0.2))

    // 两个值：上下 10，左右 20
    Text("cssPadding(10, 20)")
      .cssPadding(10, 20)
      .background(Color.blue.opacity(0.2))

    // 三个值：上 10，左右 20，下 30
    Text("cssPadding(10, 20, 30)")
      .cssPadding(10, 20, 30)
      .background(Color.green.opacity(0.2))

    // 四个值：上 10，右 20，下 30，左 40
    Text("cssPadding(10, 20, 30, 40)")
      .cssPadding(10, 20, 30, 40)
      .background(Color.purple.opacity(0.2))
  }
  .padding(20)
}
