import CoreLocation
import SwiftUI
import UIKit

struct MapAreaView: View {
  @EnvironmentObject private var vm: VehicleLiveViewModel
  @StateObject private var userLocationStore = LiveUserLocationStore()

  var body: some View {
    Group {
      if vm.isLiveWifiMode {
        wifiModeContent
      } else {
        cellularModeContent
      }
    }
    .onAppear {
      if vm.isLiveWifiMode {
        userLocationStore.stop()
      } else {
        userLocationStore.start()
      }
    }
    .onChange(of: vm.isLiveWifiMode) { isWifi in
      if isWifi {
        userLocationStore.stop()
      } else {
        userLocationStore.start()
      }
    }
    .onDisappear {
      userLocationStore.stop()
    }
  }

  private var cellularModeContent: some View {
    ZStack {
      Map4Live(
        center: gpsCoordinate,
        heading: gpsHeading,
        userCoordinate: userLocationStore.coordinate,
        userHeading: userLocationStore.heading,
        onlineStatus: vm.currLiveVehicle?.onlineStatus,
        statusIconName: vm.currLiveVehicle?.liveStatusIconName,
        statusDescription: vm.currLiveVehicle?.liveStatusDescription,
        statusColor: vm.currLiveVehicle?.liveStatusColorUi ?? UIColor(Color(hex: "0x999999")),
        zoomLevel: 15
      )
      .ignoresSafeArea(edges: .bottom)

      if shouldShowNoLocation {
        VStack {
          Spacer().frame(height: 30)
          Text("暂无车辆位置信息")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(Color(hex: "0x333333"))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.9))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
          Spacer()
        }
      }

      // 右上角，显示imei号码
      VStack {
        HStack {
          Spacer()
          VStack(alignment: .trailing, spacing: 10) {
            Text(vm.currLiveVehicle?.imei ?? "")
              .font(.system(size: 18, weight: .bold))
              .foregroundColor(ThemeColor.gray300)

            if vm.showModeBtn {
              LivePreviewModeSwitchView()
            }
          }
          .padding(.horizontal, 12)
          .padding(.top, 12)
        }
        Spacer()
      }

      // 底部按钮区域
      GeometryReader { reader in
        ZStack {
          if vm.bottomActionStatus != .talkback {
            BlurView().opacity(0.4)
          }

          VStack {
            if vm.bottomActionStatus == .talkback {
              Spacer()
            }

            LinearGradient(
              colors: [Color.white.opacity(0), Color.white],
              startPoint: .top,
              endPoint: .bottom
            )
            .frame(
              height: vm.bottomActionStatus == .talkback ? 180 : reader.size.height
            )
            .ignoresSafeArea(edges: .bottom)
          }
          .allowsHitTesting(false)
        }
      }

      BottomActionsView()
    }
  }

  private var wifiModeContent: some View {
    ZStack {
      Color(hex: "0xF2F4F7")
        .ignoresSafeArea(edges: .bottom)

      VStack {
        Spacer()
        WifiBottomActionsView()
      }
    }
  }

  private var gpsCoordinate: CLLocationCoordinate2D? {
    guard let gps = vm.currLiveVehicle?.gps else { return nil }
    let latitude = gps.latitude
    let longitude = gps.longitude
    if latitude == 0 || longitude == 0 { return nil }
    let raw = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    return GpsUtil.gps84ToGcj02(raw)
  }

  private var gpsHeading: Double? {
    guard let gps = vm.currLiveVehicle?.gps else { return nil }
    return Double(gps.direct)
  }

  private var shouldShowNoLocation: Bool {
    gpsCoordinate == nil
  }
}

private struct LivePreviewModeSwitchView: View {
  @EnvironmentObject private var vm: VehicleLiveViewModel

  var body: some View {
    VStack(alignment: .trailing, spacing: 8) {
      Button {
        vm.toggleModeMenu()
      } label: {
        HStack(spacing: 6) {
          if vm.isLivePreviewModeSwitchLoading {
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "0x666666")))
              .scaleEffect(0.8)
          }

          Text(vm.modeText)
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(Color(hex: "0x333333"))

          Image(systemName: vm.isLivePreviewModeMenuPresented ? "chevron.up" : "chevron.down")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(Color(hex: "0x8A8A8A"))
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(Color.white.opacity(0.96))
        .overlay(
          Capsule()
            .stroke(Color(hex: "0xE6E8EC"), lineWidth: 1)
        )
        .clipShape(Capsule())
      }
      .buttonStyle(.plain)
      .disabled(vm.isLivePreviewModeSwitchLoading)

      if vm.isLivePreviewModeMenuPresented {
        VStack(spacing: 0) {
          ForEach(Array(vm.livePreviewModeOptions.enumerated()), id: \.element.id) { index, option in
            Button {
              vm.setMode(to: option)
            } label: {
              HStack {
                Text(option.title)
                  .font(.system(size: 18, weight: .regular))
                  .foregroundColor(Color(hex: "0x333333"))
                  .frame(maxWidth: .infinity, alignment: .leading)
              }
              .padding(.horizontal, 20)
              .frame(height: 64)
              .background(Color.white)
            }
            .buttonStyle(.plain)

            if index < vm.livePreviewModeOptions.count - 1 {
              Divider()
                .background(Color(hex: "0xECEFF3"))
            }
          }
        }
        .frame(width: 158)
        .background(
          RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color.white.opacity(0.98))
            .shadow(color: Color.black.opacity(0.1), radius: 18, x: 0, y: 8)
        )
      }
    }
  }
}
