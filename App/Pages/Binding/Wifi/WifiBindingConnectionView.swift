import SwiftUI
import UIKit

struct WifiBindingConnectionView: View {
  private var appNavigation: AppNavigationModel {
    AppNavigationModel.shared
  }

  @ObservedObject var wifiStore: WifiStore = .shared
  @ObservedObject var bindingStore = BindingStore.shared
  @ObservedObject private var vehiclesStore = VehiclesStore.shared
  @ObservedObject private var localNetworkStore = LocalNetworkPermissionStore.shared

  private var connectedImei: String {
    wifiStore.deviceInfo?.imei?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
  }

  private var isAlreadyBoundByCurrentUser: Bool {
    guard !connectedImei.isEmpty else { return false }
    return vehiclesStore.hashVehicles[connectedImei] != nil
  }

  /// 是否可以点击绑定按钮了
  var btnDisabled: Bool {
    wifiStore.deviceInfo == nil ||
      wifiStore.deviceInfo?.imei?.isEmpty == true ||
      wifiStore.deviceInfo?.sn?.isEmpty == true ||
      isAlreadyBoundByCurrentUser
  }

  var body: some View {
    VStack(spacing: 0) {
      NavHeader(title: "Wifi绑定") {
        Text("Step 2")
          .font(.system(size: 14))
          .foregroundColor(Color(hex: "0x999999"))
      }

      VStack(spacing: 0) {
        Text("当前连接的Wifi")
          .font(.system(size: 18))
          .foregroundColor(Color(hex: "0x666666"))
          .padding(.top, 40)

        HStack {
          Image(systemName: "wifi")
            .font(.system(size: 24))
            .foregroundColor(wifiStore.isTargetWifiConnected ? Color(hex: "0x28C4FB") : .gray)

          Text(wifiStore.currentSSID ?? "未连接")
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(Color(hex: "0x333333"))
            .padding(.leading, 8)

          Spacer()

          Button {
            // Open WiFi settings
            if let url = URL(string: UIApplication.openSettingsURLString) {
              UIApplication.shared.open(url)
            }
          } label: {
            Text("更改")
              .font(.system(size: 14))
              .foregroundColor(.white)
              .padding(.horizontal, 16)
              .padding(.vertical, 6)
              .background(Color(hex: "0x28C4FB"))
              .cornerRadius(15)
          }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 20)
        .padding(.top, 12)

        if localNetworkStore.isDenied {
          LocalNetworkPermissionNoticeView {
            localNetworkStore.openAppSettings()
          }
          .padding(.top, 12)
        }

        if wifiStore.isTargetWifiConnected {
          HStack(spacing: 4) {
            Text(statusHintText)
              .font(.system(size: 16))
              .foregroundColor(Color(hex: "0x999999"))
              .padding(.top, 20)

            // 点击这个more之后得有一个弹窗，展示获取到的设备信息。其中：
            // 1. 设备信息：imei和sn 必须显示
            // 2. 如果是OBD设备，还需要展示：OBD设备（是 / 否），Chip ID，OBD SN
            // 3. 有关闭按钮
            Button {
              BottomSheetCenter.shared.show(full: true) {
                DeviceInfoSheet(
                  info: wifiStore.deviceInfo,
                  onClose: { BottomSheetCenter.shared.hide() }
                )
              }
            } label: {
              Text("更多")
                .font(.system(size: 16))
                .foregroundColor(ThemeColor.brand500)
                .padding(.top, 20)
            }
          }
        } else {
          Text("请连接\(wifiStore.targetWifiPrefixHintText)开头的设备Wifi")
            .font(.system(size: 14))
            .foregroundColor(Color(hex: "0x999999"))
            .padding(.top, 20)
        }

        Spacer()

        // 绑定按钮
        Button {
          if !btnDisabled {
            bindingStore.resetStore(bindingType: .wifi)
            bindingStore.imeiText = wifiStore.deviceInfo?.imei ?? ""
            bindingStore.snText = wifiStore.deviceInfo?.sn ?? ""

            Task {
              let success = await bindingStore.checkBindStatus()
              if success {
                appNavigation.push(bindingStore.recommendedNextStepRoute())
              }
            }
          }
        } label: {
          Text(isAlreadyBoundByCurrentUser ? "设备已绑定" : "点击绑定设备")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(btnDisabled ? Color(hex: "0x28C4FB").opacity(0.4) : Color(hex: "0x28C4FB"))
            .cornerRadius(24)
        }
        .disabled(btnDisabled)
        .padding(.horizontal, 32)
        .padding(.bottom, 40)
      }
    }
    .ignoresSafeArea()
    .navigationBarHidden(true)
    .onAppear {
      localNetworkStore.refresh()
    }
  }

  private var statusHintText: String {
    if isAlreadyBoundByCurrentUser {
      return "该设备已在您的车辆列表中"
    }
    if btnDisabled {
      return "正在从设备获取信息"
    }
    return "信息获取成功，点击下方按钮绑定"
  }
}

/// DONE-AI：这样展示，不是很美观啊！我希望，还是用那种之前用过的，底部弹出那种来完成这个任务。
private struct DeviceInfoSheet: View {
  let info: VehicleDeviceInfo?
  let onClose: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Text("设备信息")
          .font(.system(size: 18, weight: .bold))
          .foregroundColor(Color(hex: "0x111111"))
        Spacer()
        Button {
          onClose()
        } label: {
          Image(systemName: "xmark")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(Color(hex: "0x999999"))
            .frame(width: 44, height: 44)
            .background(Color(hex: "0xF5F6F7"))
            .clipShape(Circle())
        }
        .buttonStyle(.plain)
      }
      .padding(.horizontal, 20)
      .padding(.top, 24)
      .padding(.bottom, 10)

      VStack(spacing: 10) {
        infoRow(title: "IMEI", value: info?.imei ?? "-")
        infoRow(title: "SN", value: info?.sn ?? "-")
        if info?.isObdDevice == true {
          infoRow(title: "OBD设备", value: "是")
          infoRow(title: "Chip ID", value: info?.chipId ?? "-")
          infoRow(title: "OBD SN", value: info?.obdSn ?? "-")
        }
      }
      .padding(.horizontal, 20)
      .padding(.top, 8)

      Spacer().frame(height: 120)

      Button {
        onClose()
      } label: {
        Text("我知道了").FullBrandButton()
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 20 + safeAreaBottom)
    }
    .frame(maxWidth: .infinity, alignment: .top)
    .background(Color.white)
    .cornerRadius(24, corners: [.topLeft, .topRight])
  }
}

private struct LocalNetworkPermissionNoticeView: View {
  let onOpenSettings: () -> Void

  var body: some View {
    VStack(spacing: 10) {
      HStack(spacing: 8) {
        Image(systemName: "exclamationmark.triangle.fill")
          .foregroundColor(Color(hex: "0xF59E0B"))
        Text("需要本地网络权限")
          .font(.system(size: 16, weight: .medium))
          .foregroundColor(Color(hex: "0x333333"))
        Spacer()
      }

      Text("请在系统设置中开启“本地网络”权限，以便连接设备并获取信息。")
        .font(.system(size: 14))
        .foregroundColor(Color(hex: "0x666666"))
        .frame(maxWidth: .infinity, alignment: .leading)

      Button {
        onOpenSettings()
      } label: {
        Text("去设置")
          .font(.system(size: 14, weight: .medium))
          .foregroundColor(.white)
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
          .background(ThemeColor.brand500)
          .cornerRadius(16)
      }
      .frame(maxWidth: .infinity, alignment: .trailing)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .background(Color.white)
    .cornerRadius(12)
    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    .padding(.horizontal, 20)
  }
}

private func infoRow(title: String, value: String) -> some View {
  HStack {
    Text(title)
      .font(.system(size: 15))
      .foregroundColor(Color(hex: "0x666666"))
      .frame(width: 70, alignment: .leading)
    Spacer()
    Text(value)
      .font(.system(size: 15, weight: .medium))
      .foregroundColor(Color(hex: "0x333333"))
      .multilineTextAlignment(.trailing)
  }
  .padding(.horizontal, 16)
  .padding(.vertical, 12)
  .background(Color(hex: "0xF8FAFC"))
  .cornerRadius(12)
}
