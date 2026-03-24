import SwiftUI

struct WifiDirectFailurePage: View {
  let reason: WifiDirectViewModel.FailureReason
  let imei: String
  let onRetryOpen: () -> Void
  let onOpenWifiSettings: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      Spacer().frame(height: 40)

      ZStack {
        Circle()
          .fill(Color(hex: "0xF5EBEB"))
          .frame(width: 120, height: 120)
          .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)

        Image(systemName: "wifi.slash")
          .font(.system(size: 44, weight: .semibold))
          .foregroundColor(Color(hex: "0xF04B3E"))
      }

      Text(reason.title)
        .font(.system(size: 22, weight: .semibold))
        .foregroundColor(Color(hex: "0x333333"))
        .padding(.top, 54)

      Text(reason.tip)
        .font(.system(size: 16))
        .foregroundColor(Color(hex: "0x666666"))
        .padding(.top, 8)
        .multilineTextAlignment(.center)

      if reason.showsWifiCredential {
        if let vehicle = VehiclesStore.shared.hashVehicles[imei],
           let ssid = vehicle.wifi?.SSID,
           let password = vehicle.wifi?.wifiPwd
        {
          VStack(spacing: 22) {
            HStack(spacing: 12) {
              Text("WIFI：")
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(Color(hex: "0x333333"))
              Text(ssid)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color(hex: "0x333333"))
              Spacer(minLength: 0)
            }
            HStack(spacing: 12) {
              Text("密码：")
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(Color(hex: "0x333333"))
              Text(password)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color(hex: "0x333333"))
              Spacer(minLength: 0)
            }
          }
          .padding(.horizontal, 28)
          .padding(.vertical, 28)
          .frame(maxWidth: .infinity)
          .background(Color.white.opacity(0.55))
          .cornerRadius(16)
          .padding(.horizontal, 32)
          .padding(.top, 36)
        }
      }

      Spacer()

      if reason == .openFailed {
        Button(action: onRetryOpen) {
          Text("重试打开")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color(hex: "0x28C4FB"))
            .cornerRadius(24)
        }
        .padding(.horizontal, 32)
      } else {
        Button(action: onOpenWifiSettings) {
          Text("前往 WiFi 设置")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color(hex: "0x28C4FB"))
            .cornerRadius(24)
        }
        .padding(.horizontal, 32)
      }

      Spacer().frame(height: 40)
    }
    .background(Color(hex: "0xF3F4F6"))
  }
}
