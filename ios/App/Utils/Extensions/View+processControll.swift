import SwiftUI

/**
 * me: 重要说明：（千万不能删除）
 * 1. 支持点击（每次 + 1）
 * 2. 支持左右滑动增减（按照view宽度的40%作为标尺，意思就是，如果从0向右滑动40%个view的宽度，那么就达到100%了）
 * 3. 该插件，不需要处理背景色什么的。只需要处理进度
 */

struct ProgressControlModifier: ViewModifier {
  @Binding var currentValue: Int
  let totalValue: Int
  let enableHaptic: Bool
  let onCompleted: ((Int) -> Void)?
  let isDisabled: Bool

  @State private var initialProgress: CGFloat = 0
  @State private var size: CGSize = .zero
  @State private var hasValueChanged: Bool = false

  // 改变进度相关的，需要用到的数据
  @State private var startValue: Int = 0
  @State private var startPosition: CGPoint?

  // 滑动方向相关的状态
  // 用来做意图锁定
  private enum DragDirection {
    case none, horizontal, vertical
  }
  @State private var dragDirection: DragDirection = .none
  @State private var dragFrameCount: Int = 0

  private let hapticFeedback = UIImpactFeedbackGenerator(style: .light)

  private var progress: CGFloat {
    CGFloat(currentValue) / CGFloat(totalValue)
  }

  func body(content: Content) -> some View {
    content
      .background(
        GeometryReader { geometry in
          Color.clear
            .contentShape(Rectangle())  // 让 clear color 也能接收手势
            .onAppear {
              size = geometry.size
            }
        }
      )
      .gesture(
        TapGesture()
          .onEnded {
            print("TapGesture onEnded")
            if isDisabled { return }
            handleClick()
          }
      )
      .simultaneousGesture(
        DragGesture(minimumDistance: 1)
          .onChanged { value in
            if isDisabled { return }
            handleDrag(value)
          }
          .onEnded { _ in
            if isDisabled { return }
            if hasValueChanged {
              onCompleted?(currentValue)
              hasValueChanged = false
            }
            startPosition = nil
            initialProgress = 0
            // 重置滑动方向相关变量
            dragDirection = .none
            dragFrameCount = 0
          }
      )
  }

  // 处理点击事件
  private func handleClick() {
    let newValue = min(currentValue + 1, totalValue)
    if newValue != currentValue {
      withAnimation(.easeInOut(duration: 0.3)) {
        currentValue = newValue
      }
      triggerHaptic()
      hasValueChanged = true
      onCompleted?(newValue)
    }
  }

  // 处理拖动事件
  private func handleDrag(_ value: DragGesture.Value) {
    let currentPosition = value.location

    // 记录初始位置和进度
    if startPosition == nil {
      startPosition = currentPosition
      startValue = currentValue
      initialProgress = progress
      hasValueChanged = false

      // 重置滑动方向相关变量
      dragDirection = .none
      dragFrameCount = 0
    }

    // 确保有开始位置
    guard let startPos = startPosition else { return }

    // 计算水平和垂直位移
    let deltaX = currentPosition.x - startPos.x
    let deltaY = currentPosition.y - startPos.y

    // 增加帧计数
    dragFrameCount += 1

    // 如果滑动方向尚未确定，且已经累积了足够的位移或帧数，则确定滑动方向
    if dragDirection == .none {
      // 设置一个最小位移阈值，避免微小移动导致错误判断
      let minDirectionDelta: CGFloat = 5

      if dragFrameCount >= 3 || abs(deltaX) > minDirectionDelta
        || abs(deltaY) > minDirectionDelta {
        if abs(deltaX) > abs(deltaY) {
          dragDirection = .horizontal
        } else {
          dragDirection = .vertical
        }
      }
    }

    // 只有在水平滑动时才处理进度变化
    if dragDirection == .horizontal {
      let viewWidth = size.width
      let progressDelta = deltaX / (viewWidth * 0.4)  // 使用40%宽度作为基准

      let oldValue = currentValue
      let newProgress = min(max(0, initialProgress + progressDelta), 1.0)
      let newValue = Int(round(newProgress * CGFloat(totalValue)))

      if newValue != oldValue {
        withAnimation(.linear(duration: 0.1)) {
          currentValue = newValue
        }
        triggerHaptic()
        hasValueChanged = true
      }
    }
  }

  // 触发震动反馈
  private func triggerHaptic() {
    guard enableHaptic else { return }
    hapticFeedback.impactOccurred()
  }
}

extension View {
  // TODO: 这个还没有写完哈，还需要设置完成的回调事件
  func progressControl(
    currentValue: Binding<Int>,
    totalValue: Int,
    enableHaptic: Bool = true,
    onCompleted: ((Int) -> Void)? = nil,
    isDisabled: Bool = false
  ) -> some View {
    self.modifier(
      ProgressControlModifier(
        currentValue: currentValue,
        totalValue: totalValue,
        enableHaptic: enableHaptic,
        onCompleted: onCompleted,
        isDisabled: isDisabled
      )
    )
  }
}

#Preview {
  struct PreviewWrapper: View {
    @State private var currentValue = 2
    let totalValue = 5

    var body: some View {
      VStack {
        Text("点击或滑动调整进度")
          .padding()

        ZStack(alignment: .topLeading) {
          Rectangle()
            .fill(Color.blue.opacity(0.5))

          Rectangle()
            .fill(Color.blue)
            .frame(width: CGFloat(currentValue) / CGFloat(totalValue) * 380)
        }
        .frame(maxWidth: 380, maxHeight: 100)

        Text("Progress: \(currentValue)/\(totalValue)")
          .font(.title)
          .padding()
      }
      .progressControl(
        currentValue: $currentValue,
        totalValue: totalValue,
        onCompleted: { value in
          print("Progress completed with value: \(value)")
        }
      )
      .background(Color.white)
    }
  }

  return PreviewWrapper()
}
