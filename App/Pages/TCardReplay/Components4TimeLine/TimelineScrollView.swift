import SwiftUI
import UIKit

struct TimelineScrollView: UIViewRepresentable {
  let dayStartMs: Int64
  let selectedTimeMs: Int64
  let ranges: [TCardReplayRange]
  let onScrubBegin: () -> Void
  let onScrub: (Int64) -> Void
  let onSeek: (Int64) -> Void

  final class Coordinator {
    var lastSyncedDayStartMs: Int64 = 0
    var lastSyncedTimeSec: Int64 = -1
  }

  func makeCoordinator() -> Coordinator {
    // Step 1. 构建滚动同步的协调器
    Coordinator()
  }

  func makeUIView(context _: Context) -> TimelineScrollContainerView {
    // Step 1. 创建容器并绑定回调
    let view = TimelineScrollContainerView()
    view.onScrubBegin = onScrubBegin
    view.onScrub = onScrub
    view.onSeek = onSeek
    // Step 2. 初始化内容
    view.updateContent(dayStartMs: dayStartMs, selectedTimeMs: selectedTimeMs, ranges: ranges)
    return view
  }

  func updateUIView(_ uiView: TimelineScrollContainerView, context: Context) {
    // Step 1. 同步回调引用
    uiView.onScrubBegin = onScrubBegin
    uiView.onScrub = onScrub
    uiView.onSeek = onSeek

    // Step 2. 刷新时间轴数据
    uiView.updateContent(dayStartMs: dayStartMs, selectedTimeMs: selectedTimeMs, ranges: ranges)

    // Step 3. 同步滚动位置到选中时间
    let selectedSec = max(0, min(86399, (selectedTimeMs - dayStartMs) / 1000))
    if context.coordinator.lastSyncedDayStartMs != dayStartMs {
      context.coordinator.lastSyncedDayStartMs = dayStartMs
      context.coordinator.lastSyncedTimeSec = -1
    }

    if uiView.isUserInteracting == false, context.coordinator.lastSyncedTimeSec != selectedSec {
      context.coordinator.lastSyncedTimeSec = selectedSec
      uiView.scrollToSecond(selectedSec, animated: false)
    }
  }
}

final class TimelineScrollContainerView: UIView, UIScrollViewDelegate {
  var onScrubBegin: (() -> Void)?
  var onScrub: ((Int64) -> Void)?
  var onSeek: ((Int64) -> Void)?

  private let scrollView = UIScrollView()
  private let contentView = UIView()
  private let leftSpacer = UIView()
  private let rightSpacer = UIView()
  private let canvasView = TimelineCanvasView()

  private var leftSpacerWidth: NSLayoutConstraint?
  private var rightSpacerWidth: NSLayoutConstraint?
  private var canvasWidth: NSLayoutConstraint?

  private var dayStartMs: Int64 = 0
  private var selectedTimeMs: Int64 = 0
  private var ranges: [TCardReplayRange] = []
  private var lastScrubTimeMs: Int64 = 0

  private let currentZoomLevel: TimelineZoomLevel = .coarse
  private(set) var isUserInteracting: Bool = false
  private var isProgrammatic: Bool = false
  private var pendingScrollSecond: Int64?
  private var isLayoutReady: Bool = false

  override init(frame: CGRect) {
    // Step 1. 初始化视图与滚动属性
    super.init(frame: frame)
    backgroundColor = .clear

    scrollView.showsHorizontalScrollIndicator = false
    scrollView.showsVerticalScrollIndicator = false
    scrollView.bounces = true
    scrollView.alwaysBounceHorizontal = true
    scrollView.decelerationRate = .fast
    scrollView.delegate = self
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(scrollView)

    // Step 2. 约束滚动视图到容器边界
    NSLayoutConstraint.activate([
      scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
      scrollView.topAnchor.constraint(equalTo: topAnchor),
      scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])

    // Step 3. 设置内容容器与约束
    contentView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(contentView)

    NSLayoutConstraint.activate([
      contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
      contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
      contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
      contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
      contentView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
    ])

    // Step 4. 准备左右占位与画布
    leftSpacer.translatesAutoresizingMaskIntoConstraints = false
    rightSpacer.translatesAutoresizingMaskIntoConstraints = false
    canvasView.translatesAutoresizingMaskIntoConstraints = false

    contentView.addSubview(leftSpacer)
    contentView.addSubview(canvasView)
    contentView.addSubview(rightSpacer)

    // Step 5. 配置可变宽度约束
    leftSpacerWidth = leftSpacer.widthAnchor.constraint(equalToConstant: 0)
    rightSpacerWidth = rightSpacer.widthAnchor.constraint(equalToConstant: 0)
    canvasWidth = canvasView.widthAnchor.constraint(equalToConstant: 24 * currentZoomLevel.hourWidth)

    // Step 6. 绑定布局约束关系
    NSLayoutConstraint.activate([
      leftSpacer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      leftSpacer.topAnchor.constraint(equalTo: contentView.topAnchor),
      leftSpacer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      leftSpacerWidth!,

      canvasView.leadingAnchor.constraint(equalTo: leftSpacer.trailingAnchor),
      canvasView.topAnchor.constraint(equalTo: contentView.topAnchor),
      canvasView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      canvasWidth!,

      rightSpacer.leadingAnchor.constraint(equalTo: canvasView.trailingAnchor),
      rightSpacer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      rightSpacer.topAnchor.constraint(equalTo: contentView.topAnchor),
      rightSpacer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      rightSpacerWidth!,
    ])
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    // Step 1. 动态更新左右占位和画布宽度
    super.layoutSubviews()
    let half = max(0, bounds.width / 2)
    leftSpacerWidth?.constant = half
    rightSpacerWidth?.constant = half
    canvasWidth?.constant = 24 * currentZoomLevel.hourWidth
    isLayoutReady = bounds.width > 0
    applyPendingScrollIfNeeded()
  }

  func updateContent(dayStartMs: Int64, selectedTimeMs: Int64, ranges: [TCardReplayRange]) {
    // Step 1. 保存当前状态并刷新画布
    self.dayStartMs = dayStartMs
    self.selectedTimeMs = selectedTimeMs
    self.ranges = ranges
    canvasView.update(dayStartMs: dayStartMs, selectedTimeMs: selectedTimeMs, ranges: ranges, zoomLevel: currentZoomLevel)
  }

  func scrollToSecond(_ second: Int64, animated: Bool) {
    // Step 1. 计算目标位置并滚动
    let sec = max(0, min(86399, second))
    if isLayoutReady == false {
      pendingScrollSecond = sec
      return
    }
    applyScroll(to: sec, animated: animated)
  }

  private func currentSecondUnderPointer() -> Int64 {
    // Step 1. 将当前偏移转换为秒
    let pps = currentZoomLevel.pixelsPerSecond
    if pps <= 0 { return 0 }
    let sec = Double(scrollView.contentOffset.x / pps)
    return Int64(sec.rounded())
  }

  private func applyScroll(to second: Int64, animated: Bool) {
    // Step 1. 计算并应用滚动偏移
    let pps = currentZoomLevel.pixelsPerSecond
    let x = CGFloat(second) * pps
    let maxX = max(0, scrollView.contentSize.width - scrollView.bounds.width)
    let clampedX = max(0, min(maxX, x))
    isProgrammatic = true
    scrollView.setContentOffset(CGPoint(x: clampedX, y: 0), animated: animated)
    if animated == false {
      isProgrammatic = false
    }
  }

  private func applyPendingScrollIfNeeded() {
    // Step 1. 布局完成后补偿滚动
    guard let pendingScrollSecond else { return }
    scrollView.layoutIfNeeded()
    guard bounds.width > 0, scrollView.contentSize.width > 0 else { return }
    applyScroll(to: pendingScrollSecond, animated: false)
    self.pendingScrollSecond = nil
  }

  private func currentTimeMsUnderPointer() -> Int64 {
    // Step 1. 将当前秒数映射为时间戳
    let sec = max(0, min(86399, currentSecondUnderPointer()))
    return dayStartMs + sec * 1000
  }

  func scrollViewWillBeginDragging(_: UIScrollView) {
    // Step 1. 标记用户开始交互
    isUserInteracting = true
    lastScrubTimeMs = 0
    onScrubBegin?()
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    // Step 1. 过滤程序滚动和非交互状态
    if isProgrammatic { return }
    if isUserInteracting == false, scrollView.isDragging == false, scrollView.isDecelerating == false { return }
    // Step 2. 计算指针对应时间并通知外部
    let timeMs = currentTimeMsUnderPointer()
    lastScrubTimeMs = timeMs
    onScrub?(timeMs)
  }

  func scrollViewDidEndDragging(_: UIScrollView, willDecelerate decelerate: Bool) {
    // Step 1. 结束拖拽时回调最终时间
    if decelerate == false {
      isUserInteracting = false
      onSeek?(lastScrubTimeMs == 0 ? currentTimeMsUnderPointer() : lastScrubTimeMs)
    }
  }

  func scrollViewDidEndDecelerating(_: UIScrollView) {
    // Step 1. 减速结束后回调最终时间
    isUserInteracting = false
    onSeek?(lastScrubTimeMs == 0 ? currentTimeMsUnderPointer() : lastScrubTimeMs)
  }

  func scrollViewDidEndScrollingAnimation(_: UIScrollView) {
    // Step 1. 结束程序滚动标记
    isProgrammatic = false
  }
}
