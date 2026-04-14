import SwiftUI

// 通过presentationCompactAdaptor 将view转换为popover
// ios 16.4 以上
extension View {
  func toPopover() -> some View {
    if #available(iOS 16.4, *) {
      return self.presentationCompactAdaptation(.popover)
    } else {
      // TODO: 16.4 以下的，需要自己实现（目前是使用系统的sheet）
      return self
    }
  }
}
