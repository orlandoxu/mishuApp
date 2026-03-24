import SwiftUI
import UIKit

final class TimelineCanvasView: UIView {
  private let tickLayer = CAShapeLayer()
  private let emptyRangesLayer = CAShapeLayer()
  private let normalSegmentsLayer = CAShapeLayer()
  private let eventSegmentsLayer = CAShapeLayer()
  private let extraSegmentsLayer = CAShapeLayer()
  private let selectedOverlayLayer = CAShapeLayer()
  private let labelsLayer = CALayer()
  private var hourLabelLayers: [CATextLayer] = []

  private var dayStartMs: Int64 = 0
  private var selectedTimeMs: Int64 = 0
  private var ranges: [TCardReplayRange] = []
  private var zoomLevel: TimelineZoomLevel = .coarse

  override init(frame: CGRect) {
    // Step 1. 初始化基础视图状态
    super.init(frame: frame)
    isOpaque = false

    // Step 2. 配置刻度图层样式
    tickLayer.fillColor = UIColor.clear.cgColor
    tickLayer.strokeColor = UIColor(Color(hex: "0xB3B3B3")).cgColor
    tickLayer.lineWidth = 2 / UIScreen.main.scale
    tickLayer.contentsScale = UIScreen.main.scale

    // Step 3. 配置空区间色带样式
    emptyRangesLayer.fillColor = UIColor(Color(hex: "0xFAFAFB")).cgColor
    emptyRangesLayer.contentsScale = UIScreen.main.scale

    // Step 4. 配置普通区间色带样式
    normalSegmentsLayer.fillColor = UIColor(Color(hex: "0x99D4FF")).cgColor
    normalSegmentsLayer.contentsScale = UIScreen.main.scale

    // Step 5. 配置事件区间色带样式
    eventSegmentsLayer.fillColor = UIColor(Color(hex: "0x87EFAD")).cgColor
    eventSegmentsLayer.contentsScale = UIScreen.main.scale

    // Step 6. 配置额外类型色带样式
    extraSegmentsLayer.fillColor = UIColor(Color(hex: "0xFFC799")).cgColor
    extraSegmentsLayer.contentsScale = UIScreen.main.scale

    // Step 7. 配置选中覆盖层样式
    selectedOverlayLayer.fillColor = UIColor.white.withAlphaComponent(0.25).cgColor
    selectedOverlayLayer.contentsScale = UIScreen.main.scale

    // Step 8. 配置标签层缩放
    labelsLayer.contentsScale = UIScreen.main.scale

    // Step 9. 按顺序挂载图层
    layer.addSublayer(emptyRangesLayer)
    layer.addSublayer(normalSegmentsLayer)
    layer.addSublayer(eventSegmentsLayer)
    layer.addSublayer(extraSegmentsLayer)
    layer.addSublayer(tickLayer)
    layer.addSublayer(selectedOverlayLayer)
    layer.addSublayer(labelsLayer)

    // Step 10. 预构建小时标签层
    buildLabelLayersIfNeeded()
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func update(dayStartMs: Int64, selectedTimeMs: Int64, ranges: [TCardReplayRange], zoomLevel: TimelineZoomLevel) {
    // Step 1. 计算是否需要完整重建
    let needsRebuild = self.zoomLevel != zoomLevel || self.dayStartMs != dayStartMs || self.ranges != ranges
    // Step 2. 更新当前绘制状态
    self.dayStartMs = dayStartMs
    self.selectedTimeMs = selectedTimeMs
    self.ranges = ranges
    self.zoomLevel = zoomLevel
    // Step 3. 触发布局或局部刷新
    if needsRebuild {
      setNeedsLayout()
    } else {
      rebuildSelectedOverlay()
    }
  }

  override func layoutSubviews() {
    // Step 1. 让各图层填充画布
    super.layoutSubviews()
    tickLayer.frame = bounds
    emptyRangesLayer.frame = bounds
    normalSegmentsLayer.frame = bounds
    eventSegmentsLayer.frame = bounds
    extraSegmentsLayer.frame = bounds
    selectedOverlayLayer.frame = bounds
    labelsLayer.frame = bounds

    // Step 2. 重新绘制刻度、色带与文字
    rebuildTicks()
    rebuildSegments()
    rebuildLabels()
    rebuildSelectedOverlay()
  }

  private func rebuildTicks() {
    // Step 1. 计算刻度几何参数
    let path = UIBezierPath()

    let bottomY = bounds.height
    let majorH: CGFloat = min(12, bottomY)
    let minorH: CGFloat = min(5, majorH)
    let tickBottomY = bottomY

    // Step 2. 遍历分钟刻度并绘制路径
    let totalMinutes = 24 * 60
    let pps = zoomLevel.pixelsPerSecond
    let minuteWidth = pps * 60

    for minute in stride(from: 0, through: totalMinutes, by: 10) {
      let x = aligned(CGFloat(minute) * minuteWidth)
      let h = (minute % 60 == 0) ? majorH : minorH
      path.move(to: CGPoint(x: x, y: tickBottomY - h))
      path.addLine(to: CGPoint(x: x, y: tickBottomY))
    }

    // Step 3. 应用刻度路径
    tickLayer.path = path.cgPath
  }

  private func rebuildSegments() {
    // Step 1. 准备色带路径容器
    let emptyPath = UIBezierPath()
    let normalPath = UIBezierPath()
    let eventPath = UIBezierPath()
    let extraPath = UIBezierPath()

    // Step 2. 计算色带绘制区域
    let bottomY = bounds.height
    let bandH = max(0, bottomY)
    let bandY: CGFloat = 0

    // Step 3. 遍历区间并填充对应路径
    let pps = zoomLevel.pixelsPerSecond

    for r in ranges {
      let startSec = max(0, min(86400, Int64((r.startTimeMs - dayStartMs) / 1000)))
      let endSec = max(0, min(86400, Int64((r.endTimeMs - dayStartMs) / 1000)))
      if endSec <= startSec { continue }

      let x1 = aligned(CGFloat(startSec) * pps)
      let x2 = aligned(CGFloat(endSec) * pps)
      let rect = CGRect(x: x1, y: bandY, width: max(1, x2 - x1), height: bandH)

      switch r.kind {
      case .empty:
        emptyPath.append(UIBezierPath(rect: rect))
      case .event, .normal:
        switch r.historyType ?? 0 {
        case 121:
          eventPath.append(UIBezierPath(rect: rect))
        case 122, 123:
          extraPath.append(UIBezierPath(rect: rect))
        default:
          normalPath.append(UIBezierPath(rect: rect))
        }
      }
    }

    // Step 4. 应用色带路径
    emptyRangesLayer.path = emptyPath.cgPath
    normalSegmentsLayer.path = normalPath.cgPath
    eventSegmentsLayer.path = eventPath.cgPath
    extraSegmentsLayer.path = extraPath.cgPath
  }

  private func rebuildSelectedOverlay() {
    // Step 1. 清理当前选中覆盖层
    selectedOverlayLayer.path = nil
  }

  private func rebuildLabels() {
    // Step 1. 确保标签层存在
    buildLabelLayersIfNeeded()

    // Step 2. 配置文本样式与布局参数
    let labelY: CGFloat = 20
    let font = UIFont.systemFont(ofSize: 11, weight: .medium)
    let textColor = UIColor(Color(hex: "0x999999"))

    // Step 3. 逐小时更新文字内容与位置
    let hourWidth = zoomLevel.hourWidth

    for hour in 0 ..< 24 {
      let text = String(format: "%02d:00", hour)
      let textLayer = hourLabelLayers[hour]
      textLayer.string = NSAttributedString(
        string: text,
        attributes: [
          .font: font,
          .foregroundColor: textColor,
        ]
      )

      let x = aligned(CGFloat(hour) * hourWidth)
      textLayer.frame = CGRect(x: x - 20, y: labelY, width: 40, height: 14)
      textLayer.isHidden = false
    }
  }

  private func buildLabelLayersIfNeeded() {
    // Step 1. 已经构建则直接返回
    if hourLabelLayers.count == 24 { return }

    // Step 2. 清理旧的子图层
    labelsLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
    // Step 3. 重新生成小时文本图层
    hourLabelLayers = (0 ..< 24).map { _ in
      let textLayer = CATextLayer()
      textLayer.contentsScale = UIScreen.main.scale
      textLayer.alignmentMode = .center
      labelsLayer.addSublayer(textLayer)
      return textLayer
    }
  }

  private func aligned(_ value: CGFloat) -> CGFloat {
    // Step 1. 对齐到像素网格以避免模糊
    let scale = UIScreen.main.scale
    return (value * scale).rounded() / scale
  }
}
