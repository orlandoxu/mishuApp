import SwiftUI

struct VehicleDashboardView: View {
  @StateObject private var vehiclesStore: VehiclesStore = .shared

  var vehicle: VehicleModel? {
    vehiclesStore.vehicleDetailVehicle
  }

  var body: some View {
    let statusInfo = vehicle?.statusInfo
    let tripStats = vehicle?.tripStats

    // 恢复卡片顶部小三角形样式
    ZStack(alignment: .top) {
      VStack {
        let isObdDevice = !(statusInfo?.obdSn?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? false)
        let metrics = [
          DashboardMetric(value: formatTotalMiles(vehicle?.car?.totalMiles ?? 0), unit: "km", title: "总里程"),
          DashboardMetric(value: formatCount(tripStats?.totalTimes), unit: "次", title: "行程数"),
          DashboardMetric(value: formatVoltage(statusInfo?.voltage), unit: "V", title: "电瓶电压"),
          DashboardMetric(value: formatFuel(statusInfo?.averageFuelUsage), unit: "L/km", title: "百公里耗油"),
          DashboardMetric(value: formatDistance(statusInfo?.remainMileage), unit: "km", title: "剩余里程"),
          DashboardMetric(value: formatPercent(statusInfo?.remainFuel), unit: "%", title: "剩余油量"),
        ]
        let displayedMetrics = Array(metrics.prefix(isObdDevice ? 6 : 3))
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
          ForEach(displayedMetrics) { metric in
            DashboardItem(value: metric.value, unit: metric.unit, title: metric.title)
          }
        }
        .padding(16)
      }
      .background(Color.white)
      .cornerRadius(12)

      Triangle()
        .fill(Color.white)
        .frame(width: 28, height: 16)
        .offset(y: -12)
    }
    .padding(.horizontal, 16)
  }

  private func formatDistance(_ value: Int?) -> String {
    guard let value = value, value != -1 else { return "-" }
    // Assuming value is in meters or km?
    // Flutter: totalKm = totalMiles! ~/ 100 -> implying totalMiles is in 100m units?
    // Flutter: remainMileage.toString() + 'km' -> remainMileage is in km.
    // Let's check Flutter implementation again.
    // getTotalKm: totalMiles ~/ 100.
    // getRemainKm: remainMileage.toString().

    // So totalMiles / 100.
    // remainMileage is raw.
    return "\(value)"
  }

  private func formatTotalMiles(_ value: Double?) -> String {
    guard let value else { return "0" }
    return "\(Int(max(0, value).rounded()))".dropTailZero
  }

  private func formatFuel(_ value: Double?) -> String {
    guard let value = value else { return "-" }
    return String(format: "%.1f", value)
  }

  private func formatVoltage(_ value: Int?) -> String {
    guard let value = value, value != -1 else { return "-" }
    // Flutter: value / 100
    return String(format: "%.1f", Double(value) / 100.0)
  }

  private func formatPercent(_ value: Int?) -> String {
    guard let value = value, value != -1 else { return "-" }
    return "\(value)"
  }

  private func formatCount(_ value: Int?) -> String {
    guard let value = value, value >= 0 else { return "-" }
    return "\(value)"
  }
}

private struct DashboardMetric: Identifiable {
  let id = UUID()
  let value: String
  let unit: String
  let title: String
}

private struct DashboardItem: View {
  let value: String
  let unit: String
  let title: String

  var body: some View {
    VStack(spacing: 4) {
      HStack(alignment: .lastTextBaseline, spacing: 2) {
        Text(value)
          .font(.system(size: 20, weight: .bold))
          .foregroundColor(Color(hex: "0x333333"))
        Text(unit)
          .font(.system(size: 12))
          .foregroundColor(Color(hex: "0x999999"))
      }

      Text(title)
        .font(.system(size: 16))
        .foregroundColor(Color(hex: "0x666666"))
    }
  }
}

private struct Triangle: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.midX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
    path.closeSubpath()
    return path
  }
}
