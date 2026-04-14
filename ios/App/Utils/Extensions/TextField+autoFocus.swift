import SwiftUI

struct AutoFocusModifier: ViewModifier {
  var shouldAutoFocus: Bool

  func body(content: Content) -> some View {
    content.modifier(AutoFocusIOS15Modifier(shouldAutoFocus: shouldAutoFocus))
  }
}

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

struct FocusOnceModifier: ViewModifier {
  var focusOnce: Binding<Int>

  func body(content: Content) -> some View {
    content.modifier(FocusOnceIOS15Modifier(focusOnce: focusOnce))
  }
}

/// 扩展 View 来添加 autoFocus/focusOneTime，避免链式修饰后方法丢失。
extension View {
  func autoFocus(_ shouldAutoFocus: Bool = true) -> some View {
    modifier(AutoFocusModifier(shouldAutoFocus: shouldAutoFocus))
  }

  func focusOneTime(_ focusOnce: Binding<Int>) -> some View {
    modifier(FocusOnceModifier(focusOnce: focusOnce))
  }
}
