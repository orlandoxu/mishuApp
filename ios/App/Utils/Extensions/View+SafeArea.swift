import SwiftUI

#if os(iOS)
  import UIKit
#endif

extension View {
  /// 获取顶部安全区域高度
  var safeAreaTop: CGFloat {
    // 获取顶部安全区域高度
    guard
      let windowScene = UIApplication.shared.connectedScenes.first
      as? UIWindowScene,
      let window = windowScene.windows.first
    else {
      return 47 // 默认安全区域高度
    }

    return window.safeAreaInsets.top
  }

  /// 获取底部安全区域高度
  var safeAreaBottom: CGFloat {
    guard
      let windowScene = UIApplication.shared.connectedScenes.first
      as? UIWindowScene,
      let window = windowScene.windows.first
    else {
      return 0 // 默认底部安全区域高度
    }
    return window.safeAreaInsets.bottom
  }

  var windowWidth: CGFloat {
    UIScreen.main.bounds.width
  }

  var windowHeight: CGFloat {
    UIScreen.main.bounds.height
  }
}
