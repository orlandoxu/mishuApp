import SwiftUI

extension View {
  func taskFor14(perform action: @escaping () async -> Void) -> some View {
    self.task {
      await action()
    }
  }

  func taskOnce(perform action: @escaping () async -> Void) -> some View {
    self.modifier(TaskOnceOverIos15Modifier(perform: action))
  }
}

struct TaskOnceOverIos15Modifier: ViewModifier {
  @State private var hasAppeared = false
  let perform: () async -> Void

  // 使用task
  func body(content: Content) -> some View {
    content.task {
      if !hasAppeared {
        hasAppeared = true
        await perform()
      }
    }
  }
}
