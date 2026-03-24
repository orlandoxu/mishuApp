import SwiftUI

struct TCardTimelineView: View {
  let day: Date
  let selectedTimeMs: Int64
  let ranges: [TCardReplayRange]
  let canSeekPreviousRange: Bool
  let canSeekNextRange: Bool
  let onSeekPreviousRange: () -> Void
  let onSeekNextRange: () -> Void
  let onScrubBegin: () -> Void
  let onSeek: (Int64) -> Void
  @State private var scrubbingTimeMs: Int64? = nil

  var body: some View {
    // Step 1. 计算当天起点与显示时间
    let dayStartMs = Int64(day.startOfDay.timeIntervalSince1970 * 1000)
    let displayTimeMs = scrubbingTimeMs ?? selectedTimeMs

    VStack(spacing: 0) {
      // 时间和区间跳转控制（放到刻度上方）
      HStack(spacing: 16) {
        jumpButton(systemName: "chevron.left", enabled: canSeekPreviousRange, action: onSeekPreviousRange)
        Spacer()
        Text(formatTime(displayTimeMs))
          .font(.system(size: 20, weight: .bold))
          .foregroundColor(ThemeColor.brand500)
          .minimumScaleFactor(0.75)
        Spacer()
        jumpButton(systemName: "chevron.right", enabled: canSeekNextRange, action: onSeekNextRange)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 6)
      .background(Color.white)

      // Timeline Area
      ZStack(alignment: .bottom) {
        TimelineScrollView(
          dayStartMs: dayStartMs,
          selectedTimeMs: selectedTimeMs,
          ranges: ranges,
          onScrubBegin: {
            onScrubBegin()
          },
          onScrub: { timeMs in
            scrubbingTimeMs = timeMs
          },
          onSeek: { timeMs in
            scrubbingTimeMs = nil
            onSeek(timeMs)
          }
        )

        // 正中间的指针
        Rectangle()
          .fill(Color.red)
          .frame(width: 2)
          .frame(height: 50)

        // 小红点
        Circle()
          .fill(Color.red)
          .frame(width: 8, height: 8)
          .offset(y: 4)
      }
      .frame(height: 50)
      .background(Color.white)
    }
  }

  private func formatTime(_ ms: Int64) -> String {
    // Step 1. 使用毫秒时间戳生成时间文本
    let date = Date(timeIntervalSince1970: TimeInterval(ms) / 1000)
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    return formatter.string(from: date)
  }

  private func jumpButton(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Image(systemName: systemName)
        .font(.system(size: 16, weight: .semibold))
        .foregroundColor(enabled ? Color(hex: "0x666666") : Color(hex: "0xC8C8C8"))
        .frame(width: 34, height: 34)
        .background(Color(hex: "0xF5F5F5"))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
    .buttonStyle(.plain)
    .disabled(enabled == false)
    .opacity(enabled ? 1 : 0.8)
  }
}
