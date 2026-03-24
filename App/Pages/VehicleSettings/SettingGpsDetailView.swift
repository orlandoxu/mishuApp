import SwiftUI

struct SettingGpsDetailView: View {
  let imei: String
  @ObservedObject private var store = TemplateStore.shared
  @State private var gpsInfo = GpsInfo.empty
  @State private var gpsCount = 0
  @State private var enCount = 0
  @State private var en2Count = 0
  @State private var cnCount = 0
  @State private var isUpdating = false
  @State private var timer: Timer?

  var body: some View {
    VStack(spacing: 0) {
      // Color.clear.frame(height: safeAreaTop)
      NavHeader(title: "卫星定位")
      ScrollView {
        VStack(spacing: 0) {
          VStack(spacing: 0) {
            Spacer().frame(height: 17)
            HStack {
              Text("定位卫星")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "0x666666"))
            }
            .frame(maxWidth: .infinity)

            Spacer().frame(height: 16)

            HStack(spacing: 6) {
              Text("\(gpsCount)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "0x001122"))
              Text(gpsInfo.isLocated ? "已定位" : "未定位")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "0x001122"))
            }
            .frame(maxWidth: .infinity)

            Spacer().frame(height: 38)

            gpsCountRow(icon: "equipment_setting_gps_cn", title: "北斗", value: cnCount)
            dividerLine
            gpsCountRow(icon: "equipment_setting_gps_En2", title: "GLONASS", value: en2Count)
            dividerLine
            gpsCountRow(icon: "equipment_setting_gps_En", title: "GPS", value: enCount)

            speedRow

            Rectangle()
              .fill(Color(hex: "0xF5F6F7"))
              .frame(height: 5)

            HStack {
              Text("卫星信号强度")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "0x001122"))
              Spacer()
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 20)

            dividerLine

            VStack(spacing: 0) {
              ForEach(gpsInfo.satellites, id: \.self) { satellite in
                satelliteRow(satellite)
              }
            }
          }
          .background(Color.white)
          .padding(.top, 10)
        }
        .padding(.bottom, 16)
      }
      .background(Color(hex: "0xF5F6F7"))
    }
    .background(Color(hex: "0xF5F6F7"))
    .ignoresSafeArea(edges: .top)
    .onAppear {
      refreshGpsInfo()
      startTimer()
    }
    .onDisappear {
      stopTimer()
    }
  }

  private var dividerLine: some View {
    Rectangle()
      .fill(Color(hex: "0xF0F0F0"))
      .frame(height: 0.5)
      .padding(.horizontal, 15)
  }

  private func gpsCountRow(icon: String, title: String, value: Int) -> some View {
    HStack {
      HStack(spacing: 10) {
        Image(icon)
          .resizable()
          .scaledToFit()
          .frame(width: 64, height: 38)
        Text(title)
          .font(.system(size: 16))
          .foregroundColor(Color(hex: "0x001122"))
      }
      Spacer()
      Text("\(value)")
        .font(.system(size: 16))
        .foregroundColor(Color(hex: "0x001122"))
    }
    .padding(.horizontal, 15)
    .padding(.vertical, 12)
    .frame(height: 62)
  }

  private var speedRow: some View {
    HStack {
      HStack(spacing: 2) {
        Text("速度")
          .font(.system(size: 14))
          .foregroundColor(Color(hex: "0x666666"))
        Text("\(formatSpeed(gpsInfo.speed))km/h")
          .font(.system(size: 14))
          .foregroundColor(Color(hex: "0x001122"))
      }
      Spacer()
      HStack(spacing: 8) {
        HStack(spacing: 2) {
          Text("经度")
            .font(.system(size: 14))
            .foregroundColor(Color(hex: "0x666666"))
          Text(formatCoordinate(gpsInfo.longitude))
            .font(.system(size: 14))
            .foregroundColor(Color(hex: "0x001122"))
        }
        HStack(spacing: 2) {
          Text("纬度")
            .font(.system(size: 14))
            .foregroundColor(Color(hex: "0x666666"))
          Text(formatCoordinate(gpsInfo.latitude))
            .font(.system(size: 14))
            .foregroundColor(Color(hex: "0x001122"))
        }
      }
    }
    .padding(.horizontal, 15)
    .padding(.top, 12)
    .padding(.bottom, 7)
    .frame(height: 40)
  }

  private func satelliteRow(_ item: GpsSatelliteInfo) -> some View {
    HStack(spacing: 10) {
      Text("\(item.number)")
        .font(.system(size: 14))
        .frame(width: 30, alignment: .trailing)

      Image(satelliteIcon(for: item.number))
        .resizable()
        .scaledToFit()
        .frame(width: 50, height: 30)

      RoundedRectangle(cornerRadius: 7.5)
        .fill(
          LinearGradient(
            colors: [Color(hex: "0x155485"), Color(hex: "0x00f8d2")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .frame(width: barWidth(for: item.signal), height: 15)

      Spacer()

      Text("\(item.signal)")
        .font(.system(size: 14))
        .foregroundColor(Color(hex: "0x001122"))
    }
    .padding(.horizontal, 15)
    .padding(.vertical, 5)
  }

  private func satelliteIcon(for number: Int) -> String {
    if number >= 100 {
      return "equipment_setting_gps_cn"
    }
    if number >= 60 {
      return "equipment_setting_gps_En2"
    }
    return "equipment_setting_gps_En"
  }

  private func barWidth(for signal: Int) -> CGFloat {
    let clamped = max(0, min(100, signal))
    return CGFloat(clamped) / 100.0 * 200.0
  }

  private func formatSpeed(_ speed: Double) -> String {
    String(format: "%.1f", speed)
  }

  private func formatCoordinate(_ value: Double) -> String {
    String(format: "%.6f", value)
  }

  private func startTimer() {
    if timer != nil { return }
    timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
      refreshGpsInfo()
    }
  }

  private func stopTimer() {
    timer?.invalidate()
    timer = nil
  }

  private func refreshGpsInfo() {
    if isUpdating { return }
    isUpdating = true
    Task {
      let result = await SettingAPI.shared.queryGpsInfo(imei: imei) ?? []
      await MainActor.run {
        applyGpsResponse(result)
        isUpdating = false
      }
    }
  }

  private func applyGpsResponse(_ items: [SettingRemoteQueryItem]) {
    if let errorMessage = resolveErrorMessage(items) {
      ToastCenter.shared.show(errorMessage)
      return
    }
    guard let target = items.first(where: { ($0.v ?? "").contains("#") }) else {
      return
    }
    guard let value = target.v else { return }
    updateGpsInfo(from: value)
  }

  private func resolveErrorMessage(_ items: [SettingRemoteQueryItem]) -> String? {
    for item in items {
      if let e = item.e, e != "0" {
        if e == "-3" {
          return "请插入T卡"
        }
        if let match = store.errors.first(where: { $0.e == e }) {
          return match.msg
        }
        return "设置失败"
      }
      if let r = item.r, r != "0" {
        if let match = store.reasons.first(where: { $0.r == r }) {
          return match.msg
        }
        return "设置失败"
      }
    }
    return nil
  }

  private func updateGpsInfo(from raw: String) {
    let cleaned = raw.replacingOccurrences(of: "#", with: "")
    let parts = cleaned.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
    var isLocated = false
    var latitude = 0.0
    var longitude = 0.0
    var speed = 0.0
    var en = 0
    var en2 = 0
    var cn = 0
    var satellites: [GpsSatelliteInfo] = []

    if parts.indices.contains(0) {
      if let value = Int(parts[0].trimmingCharacters(in: .whitespacesAndNewlines)) {
        isLocated = value != 0
      }
    }
    if parts.indices.contains(1) {
      if let value = Double(parts[1].trimmingCharacters(in: .whitespacesAndNewlines)) {
        latitude = value / 1000
      }
    }
    if parts.indices.contains(2) {
      if let value = Double(parts[2].trimmingCharacters(in: .whitespacesAndNewlines)) {
        longitude = value / 1000
      }
    }
    if parts.indices.contains(4) {
      if let value = Double(parts[4].trimmingCharacters(in: .whitespacesAndNewlines)) {
        speed = value / 10
      }
    }
    if parts.indices.contains(6) {
      en = Int(parts[6].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }
    if parts.indices.contains(7) {
      en2 = Int(parts[7].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }
    if parts.indices.contains(8) {
      cn = Int(parts[8].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }
    if parts.indices.contains(9) {
      let stateValue = parts[9]
      if !stateValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        let signalStates = stateValue.components(separatedBy: "||")
        for state in signalStates {
          let trimmed = state.trimmingCharacters(in: .whitespacesAndNewlines)
          if trimmed.isEmpty { continue }
          let pieces = trimmed.components(separatedBy: "|")
          if pieces.count < 2 { continue }
          let number = Int(pieces[0].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
          let signal = Int(pieces[1].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
          if number > 0, signal > 0 {
            satellites.append(GpsSatelliteInfo(number: number, signal: signal))
          }
        }
      }
    }

    satellites.sort { $0.signal > $1.signal }
    gpsInfo = GpsInfo(isLocated: isLocated, latitude: latitude, longitude: longitude, speed: speed, satellites: satellites)
    gpsCount = satellites.count
    enCount = en
    en2Count = en2
    cnCount = cn
  }
}
