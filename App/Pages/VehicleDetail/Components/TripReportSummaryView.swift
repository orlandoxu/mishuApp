import SwiftUI

struct TripReportSummaryView: View {
  @StateObject private var vehiclesStore: VehiclesStore = .shared

  private var tripStats: TripStatisticalData? {
    vehiclesStore.vehicleDetailVehicle?.tripStats
  }

  private var authTravelManage: Int {
    vehiclesStore.vehicleDetailVehicle?.realtime?.authTravelManage ?? 1
  }

  private var generateTravelReport: Int {
    vehiclesStore.vehicleDetailVehicle?.realtime?.generateTravelReport ?? 1
  }

  private var shouldShowTravelManageHint: Bool {
    authTravelManage == 2
  }

  private var shouldShowGenerateTravelReportHint: Bool {
    generateTravelReport == 2
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("行程报告")
        .font(.system(size: 20, weight: .bold))
        .foregroundColor(Color(hex: "0x333333"))
        .padding(.horizontal, 16)

      VStack(spacing: 16) {
        // 驾驶评分
        HStack(alignment: .center, spacing: 10) {
          Text("\(formatScore(tripStats?.scoreAvg ?? 0 <= 0 ? 100 : tripStats?.scoreAvg ?? 0))")
            .font(.system(size: 48, weight: .bold))
            .foregroundColor(ThemeColor.brand500)

          VStack(alignment: .leading, spacing: 6) {
            Text("驾驶评分")
              .font(.system(size: 20, weight: .semibold))
              .foregroundColor(Color(hex: "0x333333"))

            HStack(spacing: 4) {
              ForEach(0 ..< 5) { index in
                Image(systemName: "star.fill")
                  .font(.system(size: 14))
                  .foregroundColor(index < filledStars(tripStats?.scoreAvg ?? 0 <= 0 ? 100 : tripStats?.scoreAvg ?? 0) ? Color(hex: "0xFFA200") : Color(hex: "0xD8D8D8"))
              }
            }
          }

          Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)

        // 其他统计项
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
          // StatItem(value: formatKilometers(tripStats?.totalMiles), unit: "km", title: "总里程")
          StatItem(value: formatHoursFromSeconds(tripStats?.totalTimeUsing), unit: "小时", title: "总时长")
          StatItem(value: formatSpeed(tripStats?.avgSpeed), unit: "km/h", title: "平均速度")
          StatItem(value: formatSpeed(tripStats?.maxSpeed), unit: "km/h", title: "最高速度")
          // StatItem(value: formatKilometers(tripStats?.maxMiles), unit: "km", title: "最长里程")
          // StatItem(value: formatTripCount(tripStats?.totalTimes), unit: "段", title: "总行程")
        }
      }
      .padding(.horizontal, 12)
      .padding(.top, 12)
      .padding(.bottom, 16)
      .background(
        LinearGradient(
          colors: [Color(hex: "#EBF9FF"), Color.white],
          startPoint: .topLeading,
          endPoint: .bottom
        )
      )
      .cornerRadius(16)
      .padding(.horizontal, 16)

      if shouldShowTravelManageHint || shouldShowGenerateTravelReportHint {
        HStack(spacing: 8) {
          Image(systemName: "exclamationmark.circle")
            .foregroundColor(.red)
          Text(shouldShowTravelManageHint ? "未开启位置权限，已暂停生成行程报告" : "未开启行程报告权限，已暂停生成行程报告")
            .font(.system(size: 14))
            .foregroundColor(Color(hex: "0x333333"))
          Spacer()
        }
        .padding(12)
        .background(Color(hex: "0xFFF0F0"))
        .cornerRadius(8)
        .padding(.horizontal, 16)
      }
    }
  }

  private func formatScore(_ value: Double?) -> Int {
    let score = Int((value ?? 0).rounded())
    return min(100, max(0, score))
  }

  private func filledStars(_ score: Double?) -> Int {
    let value = max(0, min(100, score ?? 0))
    let stars = Int(ceil(value / 20.0))
    return min(5, max(0, stars))
  }

  private func formatKilometers(_ value: Double?) -> String {
    guard let value else { return "0" }
    return "\(Int(max(0, value).rounded()))".dropTailZero
  }

  private func formatSpeed(_ value: Double?) -> String {
    guard let value else { return "0" }
    return "\(Int(max(0, value).rounded()))".dropTailZero
  }

  private func formatHoursFromSeconds(_ value: Int?) -> String {
    let seconds = max(0, value ?? 0)
    let hours = Double(seconds) / 3600.0
    if hours >= 100 {
      return "\(Int(hours.rounded()))"
    }
    return String(format: "%.1f", hours).dropTailZero
  }

  private func formatTripCount(_ value: Int?) -> String {
    return "\(max(0, value ?? 0))"
  }
}

private struct StatItem: View {
  let value: String
  let unit: String
  let title: String

  var body: some View {
    VStack(spacing: 8) {
      HStack(alignment: .lastTextBaseline, spacing: 4) {
        Text(value)
          .font(.system(size: 26, weight: .bold))
          .foregroundColor(Color(hex: "0x333333"))
        Text(unit)
          .font(.system(size: 16))
          .foregroundColor(Color(hex: "0x999999"))
      }

      Text(title)
        .font(.system(size: 14, weight: .medium))
        .foregroundColor(Color(hex: "0x666666"))
    }
  }
}
