import SwiftUI

struct CloudStorageUsageBar: Identifiable {
  let id = UUID()
  let label: String
  let fileCount: Int
}

struct CloudStorageModalData {
  let cycleDays: Int
  let bars: [CloudStorageUsageBar]
}

struct RemotePlaybackModalData {
  let leftMinutes: Int
  let totalMinutes: Int
  let remainingDays: Int
}

struct CloudStorageModal: View {
  let data: CloudStorageModalData
  let onClose: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      modalHeader(title: "云储存空间", onClose: onClose)

      VStack(alignment: .leading, spacing: 16) {
        HStack(alignment: .top) {
          VStack(alignment: .leading, spacing: 8) {
            Text("\(max(1, data.cycleDays))天循环云储存")
              .font(.system(size: 22, weight: .bold))
              .foregroundColor(Color(hex: "0x333333"))

            Text("自动覆盖超期数据")
              .font(.system(size: 16))
              .foregroundColor(Color(hex: "0x999999"))
          }

          Spacer()

          Text("尊享空间")
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(ThemeColor.brand500)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(hex: "0xEBF8FF"))
            .cornerRadius(10)
        }

        CloudStorageUsageChart(bars: data.bars)
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 22)
      .background(Color(hex: "0xF5F6F7"))
      .cornerRadius(18)
      .padding(.horizontal, 20)
      .padding(.top, 10)

      Button { onClose() } label: {
        Text("知道啦")
          .font(.system(size: 16, weight: .medium))
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .frame(height: 48)
          .background(Color(hex: "0x06BAFF"))
          .cornerRadius(24)
      }
      .padding(.horizontal, 20)
      .padding(.top, 28)
      .padding(.bottom, 20 + safeAreaBottom)
    }
    .frame(maxWidth: .infinity, alignment: .top)
    .background(Color.white)
    .cornerRadius(24, corners: [.topLeft, .topRight])
  }
}

struct RemotePlaybackModal: View {
  let data: RemotePlaybackModalData
  let onClose: () -> Void

  private var progress: Double {
    guard data.totalMinutes > 0 else { return 0 }
    let value = Double(max(0, data.leftMinutes)) / Double(data.totalMinutes)
    return min(max(value, 0), 1)
  }

  var body: some View {
    VStack(spacing: 0) {
      modalHeader(title: "远程播放时间", onClose: onClose)

      VStack(spacing: 16) {
        ZStack {
          Circle()
            .stroke(Color(hex: "0xE6E8EB"), lineWidth: 10)

          Circle()
            .trim(from: 0, to: progress)
            .stroke(
              ThemeColor.brand500,
              style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round)
            )
            .rotationEffect(.degrees(-90))

          VStack(spacing: 2) {
            Text("\(max(0, data.leftMinutes))")
              .font(.system(size: 22, weight: .bold))
              .foregroundColor(Color(hex: "0x333333"))
              + Text(" Min")
              .font(.system(size: 13, weight: .medium))
              .foregroundColor(Color(hex: "0x999999"))

            Text("剩余可用")
              .font(.system(size: 11))
              .foregroundColor(Color(hex: "0x777777"))
          }
          .padding(.top, 8)
        }
        .frame(width: 114, height: 114)
        .frame(maxWidth: .infinity)

        VStack(alignment: .center, spacing: 10) {
          Text("总量: ")
            .font(.system(size: 16))
            .foregroundColor(Color(hex: "0x777777"))
            + Text("\(max(0, data.totalMinutes))")
            .font(.system(size: 22, weight: .medium))
            .foregroundColor(Color(hex: "0x333333"))
            + Text(" 分钟")
            .font(.system(size: 16))
            .foregroundColor(Color(hex: "0x777777"))

          Text("还有 ")
            .font(.system(size: 16))
            .foregroundColor(Color(hex: "0x999999"))
            + Text("\(max(0, data.remainingDays))")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(Color(hex: "0x999999"))
            + Text("天 到期")
            .font(.system(size: 16))
            .foregroundColor(Color(hex: "0x999999"))
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .multilineTextAlignment(.center)
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 20)
      .background(Color.white)
      .cornerRadius(18)
      .padding(.horizontal, 20)
      .padding(.top, 10)

      Button { onClose() } label: {
        Text("知道啦")
          .font(.system(size: 16, weight: .medium))
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .frame(height: 48)
          .background(Color(hex: "0x06BAFF"))
          .cornerRadius(24)
      }
      .padding(.horizontal, 20)
      .padding(.top, 28)
      .padding(.bottom, 20 + safeAreaBottom)
    }
    .frame(maxWidth: .infinity, alignment: .top)
    .background(Color(hex: "0xF5F6F7"))
    .cornerRadius(24, corners: [.topLeft, .topRight])
  }
}

private struct CloudStorageUsageChart: View {
  let bars: [CloudStorageUsageBar]

  private var maxCount: Int {
    max(bars.map(\.fileCount).max() ?? 0, 1)
  }

  var body: some View {
    let chartBars = bars.isEmpty ? [CloudStorageUsageBar(label: "--/--", fileCount: 0)] : bars

    ScrollView(.horizontal, showsIndicators: false) {
      HStack(alignment: .bottom, spacing: 10) {
        ForEach(chartBars) { bar in
          VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
              .fill(ThemeColor.brand500)
              .frame(width: 30, height: height(for: bar.fileCount))

            Text(bar.label)
              .font(.system(size: 12))
              .foregroundColor(Color(hex: "0x999999"))
          }
        }
      }
      .frame(height: 118, alignment: .bottom)
      .padding(.vertical, 2)
    }
  }

  private func height(for fileCount: Int) -> CGFloat {
    let maxHeight: CGFloat = 86
    let minHeight: CGFloat = 6
    if fileCount <= 0 { return minHeight }

    let normalized = log1p(Double(fileCount)) / log1p(Double(maxCount))
    let adjusted = 0.12 + pow(normalized, 0.72) * 0.88
    return max(minHeight, CGFloat(adjusted) * maxHeight)
  }
}

private func modalHeader(title: String, onClose: @escaping () -> Void) -> some View {
  HStack {
    Spacer()
    Text(title)
      .font(.system(size: 22, weight: .bold))
      .foregroundColor(Color(hex: "0x111111"))
    Spacer()
    Button {
      onClose()
    } label: {
      Image(systemName: "xmark")
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(Color(hex: "0x999999"))
        .frame(width: 36, height: 36)
        .background(Color(hex: "0xF5F6F7"))
        .clipShape(Circle())
    }
  }
  .padding(.horizontal, 20)
  .padding(.top, 24)
  .padding(.bottom, 8)
}
