import Kingfisher
import SwiftUI
import UIKit

/// 这个类名，不要乱改，就叫这个名字
struct DeviceCardView: View {
  let vehicle: VehicleModel
  let onTapCard: () -> Void
  let onTapAction: (VehicleQuickAction) -> Void
  @ObservedObject private var wifiStore = WifiStore.shared

  // MARK: - WiFi 连接状态

  /// 是否已连接到该设备的 WiFi
  private var isWifiConnected: Bool {
    guard let vehicleWifiSSID = vehicle.wifi?.SSID, !vehicleWifiSSID.isEmpty else { return false }
    let currentSSID = wifiStore.currentSSID ?? ""
    return currentSSID == vehicleWifiSSID
  }

  /// 状态标签背景色
  private var statusTagBackgroundColor: Color {
    isWifiConnected ? ThemeColor.brand500 : Color.black.opacity(0.7)
  }

  /// 状态标签文本
  private var statusTagText: String {
    isWifiConnected ? "已连接" : vehicle.onlineStatusText
  }

  /// 播放按钮背景色
  private var playButtonBackgroundColor: Color {
    isWifiConnected ? ThemeColor.brand500 : Color.white.opacity(0.4)
  }

  /// 播放按钮边框色
  private var playButtonBorderColor: Color {
    isWifiConnected ? Color.clear : Color.white.opacity(0.6)
  }

  /// 播放按钮图标色
  private var playButtonIconColor: Color {
    isWifiConnected ? .white : .white
  }

  private var titleText: String {
    let nickname = vehicle.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
    if !nickname.isEmpty { return nickname }
    let license = vehicle.car?.carLicense.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    if !license.isEmpty { return license }
    return "未设置车牌"
  }

  private var coverURL: URL? {
    let trimmed = vehicle.car?.markImgUrl.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    guard !trimmed.isEmpty, let url = URL(string: trimmed) else { return nil }
    return url
  }

  var body: some View {
    VStack(spacing: 0) {
      // 封面图片
      Button {
        onTapCard()
      } label: {
        ZStack {
          RoundedRectangle(cornerRadius: 18)
            .fill(Color.white.opacity(0.001))

          ZStack(alignment: .center) {
            // 封面图片
            cover
              .frame(height: 130)
              .offset(y: 10)
              .frame(height: 160)
              .frame(maxWidth: .infinity)
              .background(Color.gray.opacity(0.05))
              .overlay(
                LinearGradient(
                  gradient: Gradient(colors: [Color.black.opacity(0.15), Color.black.opacity(0.0)]),
                  startPoint: .top,
                  endPoint: .center
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
              )

            ZStack(alignment: .top) {
              VStack(spacing: 0) {
                HStack(alignment: .top) {
                  // 设备状态
                  HStack(spacing: 6) {
                    if isWifiConnected {
                      Image(systemName: "wifi")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                    } else {
                      Circle()
                        .fill(vehicle.statusDotColor)
                        .frame(width: 6, height: 6)
                    }
                    Text(statusTagText)
                      .font(.system(size: 12, weight: .medium))
                      .foregroundColor(.white)
                  }
                  .padding(.horizontal, 10)
                  .padding(.vertical, 6)
                  .background(statusTagBackgroundColor)
                  .cornerRadius(6)

                  Spacer()

                  // 车牌
                  Text(titleText)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    // .foregroundColor(Color(hex: "0x333333"))
                    .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)

                Spacer()
              }
              .frame(maxWidth: .infinity)
              .frame(maxHeight: .infinity)
            }

            // 播放按钮
            ZStack {
              Circle()
                .fill(playButtonBackgroundColor)
                .frame(width: 44, height: 44)
                .overlay(
                  Circle()
                    .stroke(playButtonBorderColor, lineWidth: 1)
                )
              Image(systemName: "play.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(playButtonIconColor)
            }
          }
        }
      }
      .buttonStyle(.plain)

      HStack {
        ForEach(VehicleQuickAction.allCases, id: \.self) { action in
          Button {
            onTapAction(action)
          } label: {
            VStack(spacing: 6) {
              if action == .cloudService {
                cloudServiceIcon
              } else if let iconName = action.iconName {
                Image(iconName)
                  .resizable()
                  .scaledToFit()
                  .frame(width: 24, height: 24)
              } else {
                Image(systemName: action.systemImageName)
                  .font(.system(size: 18, weight: .regular))
                  .foregroundColor(Color(hex: "0x333333"))
                  .frame(height: 24)
              }
              Text(action.title)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "0x333333"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
          }
          .buttonStyle(.plain)
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 6)
      .background(Color.white)
    }
    .background(Color.white)
    .cornerRadius(18)
    .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 6)
  }

  private enum CloudServiceStatus {
    case active
    case expired
    case inactive
  }

  private var cloudServiceStatus: CloudServiceStatus {
    if vehicle.activeStatus == 2 || vehicle.activeStatus == 4 { return .active }
    if vehicle.activeStatus == 3 { return .expired }
    return .inactive
  }

  private var cloudServiceIcon: some View {
    ZStack(alignment: .topTrailing) {
      Image(cloudServiceStatus == .active ? "icon_service_active" : "icon_service_exp")
        .resizable()
        .scaledToFit()
        .frame(width: 24, height: 24)

      // Badge
      if cloudServiceStatus == .active {
        Text("PRO")
          .font(.system(size: 8, weight: .bold))
          .foregroundColor(.white)
          .padding(.horizontal, 2)
          .padding(.vertical, 1)
          .background(Color.orange)
          .cornerRadius(2)
          .offset(x: 8, y: -4)
      } else if cloudServiceStatus == .expired {
        Text("已过期")
          .font(.system(size: 8, weight: .medium))
          .foregroundColor(.white)
          .padding(.horizontal, 2)
          .padding(.vertical, 1)
          .background(Color.gray)
          .cornerRadius(2)
          .offset(x: 12, y: -4)
      } else {
        Text("未激活")
          .font(.system(size: 8, weight: .medium))
          .foregroundColor(.white)
          .padding(.horizontal, 2)
          .padding(.vertical, 1)
          .background(Color.gray)
          .cornerRadius(2)
          .offset(x: 12, y: -4)
      }
    }
  }

  @ViewBuilder
  private var cover: some View {
    if let url = coverURL {
      KFImage(url)
        .resizable()
        .scaledToFit()
    } else {
      placeholderCover
    }
  }

  private var placeholderCover: some View {
    ZStack {
      Color.gray.opacity(0.15)
      Image(systemName: "car.fill")
        .font(.system(size: 44, weight: .regular))
        .foregroundColor(Color.gray.opacity(0.35))
    }
  }
}
