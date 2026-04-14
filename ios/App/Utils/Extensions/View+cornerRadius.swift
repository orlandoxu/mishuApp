import SwiftUI

/// 定义圆角的位置
struct RoundedCorner: Shape {
  var radius: CGFloat = .infinity
  var corners: UIRectCorner = .allCorners

  func path(in rect: CGRect) -> Path {
    let path = UIBezierPath(
      roundedRect: rect,
      byRoundingCorners: corners,
      cornerRadii: CGSize(width: radius, height: radius)
    )
    return Path(path.cgPath)
  }
}

/// View扩展，支持特定角落的圆角
extension View {
  /// 为视图添加特定角落的圆角
  /// - Parameters:
  ///   - radius: 圆角半径
  ///   - corners: 需要应用圆角的角落
  /// - Returns: 应用了特定角落圆角的视图
  func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
    clipShape(RoundedCorner(radius: radius, corners: corners))
  }
}

// MARK: - Preview
#Preview {
  VStack(spacing: 20) {
    // 所有角落圆角
    Text("所有角落圆角")
      .padding()
      .background(Color.blue.opacity(0.2))
      .cornerRadius(10)

    // 顶部圆角
    Text("顶部圆角")
      .padding()
      .background(Color.green.opacity(0.2))
      .cornerRadius(10, corners: [.topLeft, .topRight])

    // 底部圆角
    Text("底部圆角")
      .padding()
      .background(Color.orange.opacity(0.2))
      .cornerRadius(10, corners: [.bottomLeft, .bottomRight])

    // 左侧圆角
    Text("左侧圆角")
      .padding()
      .background(Color.purple.opacity(0.2))
      .cornerRadius(10, corners: [.topLeft, .bottomLeft])

    // 右侧圆角
    Text("右侧圆角")
      .padding()
      .background(Color.red.opacity(0.2))
      .cornerRadius(10, corners: [.topRight, .bottomRight])
  }
  .padding()
}
