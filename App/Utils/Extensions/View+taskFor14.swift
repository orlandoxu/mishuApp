import SwiftUI

extension View {
  func taskFor14(perform action: @escaping () async -> Void) -> some View {
    if #available(iOS 15.0, *) {
      // iOS 15 及以上直接使用 .task
      return self.task {
        await action()
      }
    } else {
      // iOS 14 及以下使用 onAppear
      return self.modifier(TaskFor14Modifier(perform: action))
    }
  }

  func taskOnce(perform action: @escaping () async -> Void) -> some View {
    if #available(iOS 15.0, *) {
      return self.modifier(TaskOnceOverIos15Modifier(perform: action))
    } else {
      return self.modifier(TaskFor14OnceModifier(perform: action))
    }
  }
}

@available(iOS 15.0, *)
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

struct TaskFor14Modifier: ViewModifier {
  let perform: () async -> Void

  func body(content: Content) -> some View {
    content.onAppear {
      Task {
        await perform()
      }
    }
  }
}

struct TaskFor14OnceModifier: ViewModifier {
  @State private var hasAppeared = false
  let perform: () async -> Void

  func body(content: Content) -> some View {
    content.onAppear {
      if !hasAppeared {
        Task {
          await perform()
        }
        hasAppeared = true
      }
    }
  }
}
