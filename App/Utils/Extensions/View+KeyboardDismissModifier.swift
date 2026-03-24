/**
 * important!!!
 * dismissKeyboardOnTap.swift
 * 注意，这个插件，有一个非常奇葩的问题：
 * 不能修饰（NavigationStack / NavigationView,只能修饰子view），否者，会有很多奇葩问题
 * 不知道为什么！ai改了一整天，一直有这个问题。
 * 在github上找的所有类似代码，都有这个问题
 * 从github代码仓库来看，目前代码，就是标准答案！
 */

import SwiftUI

public struct DismissKeyboardOnTap: ViewModifier {
  public func body(content: Content) -> some View {
    #if os(macOS)
      return content
    #else
      return content.gesture(tapGesture)
    #endif
  }

  private var tapGesture: some Gesture {
    TapGesture().onEnded(endEditing)
  }

  private func endEditing() {
    // 自己写的插件
    UIApplication.shared.dismissKeyboard()

    // 注意：下面这个代码，在多窗口中，有一定的优势。
    // 一般情况下，用不上
    // UIApplication.shared.connectedScenes
    //   .filter { $0.activationState == .foregroundActive }
    //   .map { $0 as? UIWindowScene }
    //   .compactMap({ $0 })
    //   .first?.windows
    //   .filter { $0.isKeyWindow }
    //   .first?.endEditing(true)
  }
}

extension View {
  public func dismissKeyboardOnTap() -> some View {
    modifier(DismissKeyboardOnTap())
  }
}
