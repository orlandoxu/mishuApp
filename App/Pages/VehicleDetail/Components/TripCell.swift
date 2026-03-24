import SwiftUI

struct TripCell: View {
  let trip: TripData
  @State private var isExpanded: Bool = false
  @State private var isLoadingAddress: Bool = false
  @State private var startAddress: String = ""
  @State private var endAddress: String = ""
  @State private var isDeleteConfirmPresented: Bool = false
  @State private var isDeleting: Bool = false
  @ObservedObject private var appNavigation = AppNavigationModel.shared

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // 1. Header: Date + Trash Icon
      // 注意：Header 需要在白色卡片外部，所以我们先渲染 Header，再渲染卡片
      HStack {
        Text(formatDate(trip.startTime))
          .font(.system(size: 16))
          .foregroundColor(Color(hex: "0x333333"))

        Spacer()

        Button {
          isDeleteConfirmPresented = true
        } label: {
          Image(systemName: "trash")
            .font(.system(size: 16))
            .foregroundColor(Color(hex: "0x999999"))
        }
        .disabled(isDeleting)
      }
      .padding(.bottom, 12)
      .padding(.horizontal, 16) // Align with card visual

      // 2. Card Content
      VStack(alignment: .leading, spacing: 0) {
        // 城市和得分
        HStack(alignment: .firstTextBaseline) {
          if trip.startCity == trip.endCity {
            Text(trip.startCity.isEmpty ? "-" : trip.startCity)
              .font(.system(size: 18, weight: .medium))
              .foregroundColor(Color(hex: "0x333333"))
          } else {
            HStack(spacing: 8) {
              Text(trip.startCity.isEmpty ? "-" : trip.startCity)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color(hex: "0x333333"))

              Image(systemName: "arrow.right")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "0x999999"))

              Text(trip.endCity.isEmpty ? "-" : trip.endCity)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color(hex: "0x333333"))
            }
          }

          Spacer()

          HStack(alignment: .lastTextBaseline, spacing: 2) {
            Text(String(format: "%.0f", trip.score))
              .font(.system(size: 24, weight: .bold))
              .foregroundColor(Color(hex: "0x06BAFF"))
            Text("分")
              .font(.system(size: 14, weight: .medium))
              .foregroundColor(Color(hex: "0x06BAFF"))
          }
        }
        .padding(.bottom, 8)

        // Summary: Duration + Distance
        summaryText
          .font(.system(size: 14))
          .foregroundColor(Color(hex: "0x666666"))
          .padding(.bottom, 12)

        // Location Toggle Button OR Address View
        if !isExpanded {
          Button {
            expandAndLoadAddress()
          } label: {
            HStack(spacing: 4) {
              if isLoadingAddress {
                ProgressView()
                  .scaleEffect(0.8)
                  .frame(height: 14)
              } else {
                Image(systemName: "location")
                  .font(.system(size: 14))
                  .frame(height: 14)
              }
              Text(isLoadingAddress ? "解析地址中..." : "点击查看详细位置")
                .font(.system(size: 14))
            }
            .foregroundColor(Color(hex: "0x06BAFF"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color(hex: "0xF0FAFF"))
            .cornerRadius(8)
          }
          .disabled(isLoadingAddress)
          .padding(.bottom, 12)
        } else {
          // Expanded Location Details (Replaces the button)
          VStack(alignment: .leading, spacing: 12) {
            // Start Address
            HStack(alignment: .top, spacing: 8) {
              Circle()
                .fill(Color(hex: "0x52C41A"))
                .frame(width: 8, height: 8)
                .padding(.top, 6)

              Text(startAddress.isEmpty ? "未知起点" : startAddress)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "0x666666"))
                .lineLimit(2)
            }

            // End Address
            HStack(alignment: .top, spacing: 8) {
              Circle()
                .fill(Color(hex: "0xFF4D4F"))
                .frame(width: 8, height: 8)
                .padding(.top, 6)

              Text(endAddress.isEmpty ? "未知终点" : endAddress)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "0x666666"))
                .lineLimit(2)
            }
          }
          .padding(12)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color(hex: "0xF0FAFF"))
          .cornerRadius(8)
          .padding(.bottom, 12)
        }

        // Data Grid
        // If OBD, show 4 items. Else show 2 items.
        // Items: Max Speed, Avg Speed, Fuel (OBD), Fuel Avg (OBD)
        let isOBD = (trip.obd == 1) || (trip.fuelUsage > 0)

        HStack(spacing: 12) {
          // Column 1
          VStack(spacing: 12) {
            TripStatCard(
              value: formatSpeed(trip.maxSpeed),
              unit: "km/h",
              title: "最高时速" // Screenshot title
            )

            if isOBD {
              TripStatCard(
                value: String(format: "%.1f", trip.fuelUsage),
                unit: "L",
                title: "油耗"
              )
            }
          }

          // Column 2
          VStack(spacing: 12) {
            TripStatCard(
              value: formatSpeed(trip.avgSpeed),
              unit: "km/h",
              title: "每小时平均速度"
            )

            if isOBD {
              TripStatCard(
                value: String(format: "%.1f", trip.fuelAvg),
                unit: "L/百公里",
                title: "百公里耗油"
              )
            }
          }
        }
      }
      .padding(16)
      .background(Color.white)
      .cornerRadius(12)
      .contentShape(Rectangle())
      .gesture(TapGesture().onEnded(openTripTrack), including: .gesture)
    }
    .padding(.top, 16)
    .onAppear {
      // Initialize addresses from trip data
      startAddress = trip.startAddr
      endAddress = trip.endAddr
    }
    .alert(isPresented: $isDeleteConfirmPresented) {
      Alert(
        title: Text("删除行程？"),
        message: Text("删除后不可恢复"),
        primaryButton: .destructive(Text("删除"), action: deleteTrip),
        secondaryButton: .cancel(Text("取消"))
      )
    }
  }

  /// Logic
  private func expandAndLoadAddress() {
    // If we already have detailed addresses (not empty and likely not placeholders), just expand
    // But user requirement says "call backend because it's paid", so we might want to force call
    // However, if we already called it before (state preserved), we shouldn't call again?
    // Let's assume if it's not empty, we display it. But if user clicks, maybe they want "detailed"?
    // The requirement says "点击查看详细位置，点击之后会展开详细的位置信息...因为这个要付费，所以是点一下才解析".
    // This implies the initial trip.startAddr might be rough or empty.

    // Check if we need to fetch
    // If addresses are empty or look like coordinates/unknown, fetch.
    // For now, let's trigger fetch if we are not expanded.

    if !startAddress.isEmpty, !endAddress.isEmpty, startAddress != "未知起点", endAddress != "未知终点" {
      withAnimation {
        isExpanded = true
      }
      return
    }

    isLoadingAddress = true
    Task {
      // Call API
      if let result = await TripAPI.shared.travelReGeo(trip.id) {
        await MainActor.run {
          self.startAddress = result.startAddr
          self.endAddress = result.endAddr
          self.isLoadingAddress = false
          withAnimation {
            self.isExpanded = true
          }
        }
      } else {
        await MainActor.run {
          self.isLoadingAddress = false
          // Even if failed, maybe expand to show what we have? Or show error toast?
          // For now expand with current values
          withAnimation {
            self.isExpanded = true
          }
        }
      }
    }
  }

  /// Helpers
  private func formatDate(_ timestamp: Int64) -> String {
    guard timestamp > 0 else { return "-" }

    let seconds: TimeInterval
    if timestamp >= 1_000_000_000_000 {
      seconds = TimeInterval(timestamp) / 1000
    } else {
      seconds = TimeInterval(timestamp)
    }

    let date = Date(timeIntervalSince1970: seconds)
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy/MM/dd HH:mm"
    return formatter.string(from: date)
  }

  private var summaryText: Text {
    Text("耗时 ")
      + Text("\(trip.time / 60)").fontWeight(.bold)
      + Text(" 分钟，行驶 ")
      + Text(formatDistance(trip.space)).fontWeight(.bold)
      + Text(" km")
  }

  private func openTripTrack() {
    let trimmed = trip.trackUrl.trimmingCharacters(in: .whitespacesAndNewlines)
    guard
      let url = URL(string: trimmed),
      let scheme = url.scheme?.lowercased(),
      scheme == "http" || scheme == "https"
    else {
      ToastCenter.shared.show("行程链接无效")
      return
    }
    appNavigation.push(.web(url: trimmed, title: "行程轨迹"))
  }

  private func deleteTrip() {
    if isDeleting { return }
    if trip.travelId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      ToastCenter.shared.show("行程信息缺失")
      return
    }

    isDeleting = true
    Task {
      let result = await TripAPI.shared.deleteTrip([trip.id])
      await MainActor.run {
        isDeleting = false
        if result == nil {
          ToastCenter.shared.show("删除失败，请稍后再试")
          return
        }

        if let imei = VehiclesStore.shared.vehicleDetailImei, !imei.isEmpty {
          withAnimation {
            VehiclesStore.shared.updateVehicle(imei: imei) { vehicle in
              vehicle.tripList.removeAll { $0.id == trip.id }
            }
          }
        }
      }
    }
  }

  private func formatDistance(_ value: Double) -> String {
    return String(format: "%.1f", value)
  }

  private func formatSpeed(_ value: Double) -> String {
    return String(format: "%.1f", value)
  }
}

private struct TripStatCard: View {
  let value: String
  let unit: String
  let title: String

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(alignment: .lastTextBaseline, spacing: 2) {
        Text(value)
          .font(.system(size: 20, weight: .bold)) // Screenshot shows large number
          .foregroundColor(Color(hex: "0x333333"))

        Text(unit)
          .font(.system(size: 12))
          .foregroundColor(Color(hex: "0x999999"))
      }

      Text(title)
        .font(.system(size: 12))
        .foregroundColor(Color(hex: "0x666666"))
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .strokeBorder(Color(hex: "0xEEEEEE"), lineWidth: 1)
    )
  }
}
