import SwiftUI

/// 兼容 iOS 13+，iOS 15 以下仅保持可编译且不自动聚焦
struct AutoFocusModifier: ViewModifier {
  var shouldAutoFocus: Bool

  func body(content: Content) -> some View {
    if #available(iOS 15.0, *) {
      content.modifier(AutoFocusIOS15Modifier(shouldAutoFocus: shouldAutoFocus))
    } else {
      content
    }
  }
}

@available(iOS 15.0, *)
private struct AutoFocusIOS15Modifier: ViewModifier {
  @FocusState private var isFocused: Bool
  var shouldAutoFocus: Bool

  func body(content: Content) -> some View {
    content
      .focused($isFocused)
      .onAppear {
        if shouldAutoFocus {
          isFocused = true
        }
      }
  }
}

// 下面是想办法控制 focus 状态

@available(iOS 15.0, *)
private struct FocusOnceIOS15Modifier: ViewModifier {
  @FocusState private var isFocused: Bool
  var focusOnce: Binding<Int>

  func body(content: Content) -> some View {
    content
      .focused($isFocused)
      .onChange(of: focusOnce.wrappedValue) { newValue in
        if newValue > 0 {
          // 建议加一点微小的延时，防止在某些界面切换动画中键盘弹不出来
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isFocused = true
          }
        }
      }
  }
}

/// 兼容 iOS 13+，iOS 15 以下仅保持可编译且不自动聚焦
struct FocusOnceModifier: ViewModifier {
  var focusOnce: Binding<Int>

  func body(content: Content) -> some View {
    if #available(iOS 15.0, *) {
      content.modifier(FocusOnceIOS15Modifier(focusOnce: focusOnce))
    } else {
      content
    }
  }
}

/// 扩展 View 来添加 autoFocus/focusOneTime，避免链式修饰后方法丢失。
extension View {
  func autoFocus(_ shouldAutoFocus: Bool = true) -> some View {
    modifier(AutoFocusModifier(shouldAutoFocus: shouldAutoFocus))
  }

  /// 支持ios 13+，非常麻烦
  func focusOneTime(_ focusOnce: Binding<Int>) -> some View {
    modifier(FocusOnceModifier(focusOnce: focusOnce))
  }
}
