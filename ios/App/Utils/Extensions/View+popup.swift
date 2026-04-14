import SwiftUI

// 从屏幕底部，弹一个窗口出来
// 提供两个功能 popup / popupLink
//
// 该方法，是纯SwiftUI的方法，有UIKit的UIWindow方法，但是：
// UIWindow的方法，AI写了很多遍，一直有很严重的bug（严重到无法使用）
// 所以，最后放弃了。使用了SwiftUI的方法，该方法原理是在NavigationView内的第一个元素
// 调用registerPopupContainer()方法，然后就可以在任何地方调用popup和popupLink方法了

// MARK: - 弹窗位置枚举

/// 弹窗位置
enum PopupPosition {
  case top
  case center
  case bottom

  var initialOffset: CGFloat {
    switch self {
    case .top: return -UIScreen.main.bounds.height
    case .center: return UIScreen.main.bounds.height
    case .bottom: return UIScreen.main.bounds.height
    }
  }

  var finalOffset: CGFloat {
    switch self {
    case .top: return 0
    case .center: return 0
    case .bottom: return 0
    }
  }

  var alignment: Alignment {
    switch self {
    case .top: return .top
    case .center: return .center
    case .bottom: return .bottom
    }
  }
}

// MARK: - 弹窗配置

/// 弹窗配置
struct PopupConfiguration {
  var backgroundColor: Color = Color.black.opacity(0.15)
  var position: PopupPosition = .center
  var animationDuration: Double = 0.25
  var offset: CGFloat = 0  // 添加偏移量参数
}

// MARK: - 弹窗状态管理

/// 弹窗状态管理器
class PopupManager: ObservableObject {
  @Published var activePopup: AnyView?
  @Published var isPresented = false
  @Published var contentOffset: CGFloat = UIScreen.main.bounds.height
  @Published var configuration = PopupConfiguration()

  // 添加一个标志，表示是否正在动画中
  private var isAnimating = false

  func showPopup<Content: View>(
    _ content: Content,
    configuration: PopupConfiguration
  ) {
    // 如果正在动画中，不处理新的请求
    guard !isAnimating else { return }

    activePopup = AnyView(content)
    self.configuration = configuration
    contentOffset = configuration.position.initialOffset
    isAnimating = true

    // 先设置内容，然后显示弹窗
    DispatchQueue.main.async {
      self.isPresented = true

      // 添加动画
      withAnimation(.easeOut(duration: configuration.animationDuration)) {
        // 应用最终偏移量和额外偏移
        self.contentOffset = self.getFinalOffsetWithAdjustment()
      }

      // 动画完成后重置标志
      DispatchQueue.main.asyncAfter(
        deadline: .now() + configuration.animationDuration
      ) {
        self.isAnimating = false
      }
    }
  }

  // 计算最终偏移量（包含额外偏移）
  private func getFinalOffsetWithAdjustment() -> CGFloat {
    let baseOffset = configuration.position.finalOffset

    // 根据位置应用不同的偏移方向
    switch configuration.position {
    case .top:
      // 顶部弹窗，正值向下偏移
      return baseOffset + configuration.offset
    case .center:
      // 中间弹窗，直接应用偏移
      return baseOffset + configuration.offset
    case .bottom:
      // 底部弹窗，负值向上偏移
      return baseOffset - configuration.offset
    }
  }

  func dismissPopup() {
    // 如果正在动画中，不处理新的请求
    guard !isAnimating else { return }
    isAnimating = true

    // 先执行动画
    withAnimation(.easeIn(duration: configuration.animationDuration)) {
      contentOffset = configuration.position.initialOffset
    }

    // 动画完成后隐藏弹窗
    DispatchQueue.main.asyncAfter(
      deadline: .now() + configuration.animationDuration
    ) {
      self.isPresented = false
      self.activePopup = nil
      self.isAnimating = false

      // 发送弹窗关闭通知
      NotificationCenter.default.post(
        name: NSNotification.Name("PopupDismissed"),
        object: nil
      )
    }
  }
}

// MARK: - 环境键

/// 弹窗管理器环境键
private struct PopupManagerKey: EnvironmentKey {
  static let defaultValue: PopupManager? = nil
}

/// 弹窗关闭函数环境键
struct PopupDismissKey: EnvironmentKey {
  static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
  var popupManager: PopupManager? {
    get { self[PopupManagerKey.self] }
    set { self[PopupManagerKey.self] = newValue }
  }

  var popupDismiss: () -> Void {
    get { self[PopupDismissKey.self] }
    set { self[PopupDismissKey.self] = newValue }
  }
}

// MARK: - 弹窗容器

/// 弹窗容器视图
struct PopupContainerView<Content: View>: View {
  @StateObject private var manager = PopupManager()
  let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    ZStack {
      // 主内容
      content
        .environment(\.popupManager, manager)

      // 弹窗层
      if manager.isPresented, let popup = manager.activePopup {
        manager.configuration.backgroundColor
          .ignoresSafeArea()
          .contentShape(Rectangle())
          .onTapGesture {
            manager.dismissPopup()
          }
          .transition(.opacity)

        ZStack(alignment: manager.configuration.position.alignment) {
          Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)

          popup
            .environment(\.popupDismiss, { manager.dismissPopup() })
            .offset(y: manager.contentOffset)
        }
      }
    }
    .animation(.easeInOut(duration: 0.25), value: manager.isPresented)
  }
}

// MARK: - 视图扩展

extension View {
  /// 注册弹窗容器
  /// - Returns: 包含弹窗容器的视图
  func registerPopupContainer() -> some View {
    PopupContainerView {
      self
    }
  }

  /// 显示弹窗
  /// - Parameters:
  ///   - isPresented: 控制弹窗显示的绑定
  ///   - backgroundColor: 弹窗背景色，默认为黑色半透明
  ///   - position: 弹窗位置，默认为中间
  ///   - offset: 弹窗位置的额外偏移量，默认为0
  ///   - content: 弹窗内容
  /// - Returns: 修饰后的视图
  func popup<Content: View>(
    isPresented: Binding<Bool>,
    backgroundColor: Color = Color.black.opacity(0.15),
    position: PopupPosition = .center,
    offset: CGFloat = 0,
    @ViewBuilder content: @escaping () -> Content
  ) -> some View {
    modifier(
      PopupViewModifier(
        isPresented: isPresented,
        configuration: PopupConfiguration(
          backgroundColor: backgroundColor,
          position: position,
          offset: offset
        ),
        content: content
      )
    )
  }
}

// MARK: - 弹窗修饰符

/// 弹窗视图修饰符
struct PopupViewModifier<PopupContent: View>: ViewModifier {
  @Binding var isPresented: Bool
  let configuration: PopupConfiguration
  let content: () -> PopupContent

  @Environment(\.popupManager) private var manager

  // 添加一个ID用于通知观察者
  private let observerId = UUID()

  init(
    isPresented: Binding<Bool>,
    configuration: PopupConfiguration = PopupConfiguration(),
    @ViewBuilder content: @escaping () -> PopupContent
  ) {
    self._isPresented = isPresented
    self.configuration = configuration
    self.content = content
  }

  func body(content: Content) -> some View {
    content
      .onChange(of: isPresented) { newValue in
        if newValue {
          if let manager = manager {
            manager.showPopup(self.content(), configuration: configuration)

            // 监听弹窗关闭事件，同步更新isPresented状态
            NotificationCenter.default.addObserver(
              forName: NSNotification.Name("PopupDismissed"),
              object: nil,
              queue: .main
            ) { _ in
              if self.isPresented {
                self.isPresented = false
              }
            }
          } else {
            print("警告: 未找到弹窗管理器，请确保在视图层次结构中调用了 registerPopupContainer()")
            DispatchQueue.main.async {
              self.isPresented = false
            }
          }
        }
      }
      .onDisappear {
        // 移除通知观察者
        NotificationCenter.default.removeObserver(observerId)
      }
  }
}

// MARK: - 弹窗链接

/// 弹窗链接组件
struct PopupLink<Label: View, Destination: View>: View {
  private let label: Label
  private let destination: Destination
  private let backgroundColor: Color
  private let position: PopupPosition
  private let offset: CGFloat
  @State private var isPresented = false

  init(
    destination: Destination,
    backgroundColor: Color = Color.black.opacity(0.15),
    position: PopupPosition = .center,
    offset: CGFloat = 0,
    label: Label
  ) {
    self.destination = destination
    self.backgroundColor = backgroundColor
    self.position = position
    self.offset = offset
    self.label = label
  }

  init(
    destination: Destination,
    backgroundColor: Color = Color.black.opacity(0.15),
    position: PopupPosition = .center,
    offset: CGFloat = 0,
    @ViewBuilder label: () -> Label
  ) {
    self.destination = destination
    self.backgroundColor = backgroundColor
    self.position = position
    self.offset = offset
    self.label = label()
  }

  init(
    @ViewBuilder destination: () -> Destination,
    backgroundColor: Color = Color.black.opacity(0.15),
    position: PopupPosition = .center,
    offset: CGFloat = 0,
    @ViewBuilder label: () -> Label
  ) {
    self.destination = destination()
    self.backgroundColor = backgroundColor
    self.position = position
    self.offset = offset
    self.label = label()
  }

  var body: some View {
    Button {
      isPresented = true
    } label: {
      label
    }
    .popup(
      isPresented: $isPresented,
      backgroundColor: backgroundColor,
      position: position,
      offset: offset
    ) {
      destination
    }
  }
}

/// 便捷初始化方法
extension PopupLink where Label == Text {
  init(
    _ titleKey: String,
    destination: Destination,
    backgroundColor: Color = Color.black.opacity(0.15),
    position: PopupPosition = .center,
    offset: CGFloat = 0
  ) {
    self.init(
      destination: destination,
      backgroundColor: backgroundColor,
      position: position,
      offset: offset
    ) {
      Text(titleKey)
    }
  }

  init(
    _ titleKey: String,
    backgroundColor: Color = Color.black.opacity(0.15),
    position: PopupPosition = .center,
    offset: CGFloat = 0,
    @ViewBuilder destination: () -> Destination
  ) {
    self.init(
      destination: destination(),
      backgroundColor: backgroundColor,
      position: position,
      offset: offset
    ) {
      Text(titleKey)
    }
  }
}

// MARK: - 使用示例
/*
 使用示例：

 // 顶部弹窗，向下偏移20
 .popup(
   isPresented: $showPopup,
   position: .top,
   offset: 20
 ) {
   YourPopupContent()
 }

 // 底部弹窗，向上偏移30
 .popup(
   isPresented: $showPopup,
   position: .bottom,
   offset: 30
 ) {
   YourPopupContent()
 }

 // 中间弹窗，向下偏移10
 .popup(
   isPresented: $showPopup,
   position: .center,
   offset: 10
 ) {
   YourPopupContent()
 }

 // 使用PopupLink
 PopupLink(
   "打开弹窗",
   position: .bottom,
   offset: 30
 ) {
   YourPopupContent()
 }
 */
