import SwiftUI

/// 目前是首页
struct VehicleListView: View {
  @StateObject private var vehiclesStore: VehiclesStore
  private let shouldAutoRefresh: Bool
  @ObservedObject private var appNavigation = AppNavigationModel.shared
  @ObservedObject private var locationStore = LocationPermissionStore.shared
  @ObservedObject private var localNetworkStore = LocalNetworkPermissionStore.shared
  @ObservedObject private var webSocketStore = WebSocketStore.shared
  @State private var showUnbindAlert = false
  @State private var pendingUnbindImei = ""

  @MainActor
  init(vehiclesStore: VehiclesStore = .shared, shouldAutoRefresh: Bool = true) {
    _vehiclesStore = StateObject(wrappedValue: vehiclesStore)
    self.shouldAutoRefresh = shouldAutoRefresh
  }

  var body: some View {
    ZStack(alignment: .top) {
      LoginBackgroundView()

      VStack(spacing: 20) {
        VehicleHeaderView(
          onlineCountText: onlineCountText,
          onSelectAddMenu: handleBindMenuAction
        )
        .padding(.top, safeAreaTop - 12)
        .padding(.horizontal, 20)

        ScrollView(.vertical, showsIndicators: false) {
          VStack(alignment: .leading, spacing: 16) {
            if locationStore.isDenied {
              HStack(spacing: 12) {
                Text("地图服务与WiFi绑定需要使用位置权限")
                  .font(.system(size: 16))
                  .foregroundColor(Color(hex: "0x333333"))
                Spacer()
                Button {
                  locationStore.openAppSettings()
                } label: {
                  Text("去设置")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "0x28C4FB"))
                    .cornerRadius(12)
                }
              }
              .padding(.horizontal, 16)
              .padding(.vertical, 14)
              .background(Color(hex: "0xFFF3D9"))
              .cornerRadius(12)
            }

            if localNetworkStore.isDenied {
              HStack(spacing: 12) {
                Text("需要本地网络权限连接设备")
                  .font(.system(size: 16))
                  .foregroundColor(Color(hex: "0x333333"))
                Spacer()
                Button {
                  localNetworkStore.openAppSettings()
                } label: {
                  Text("去设置")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "0x28C4FB"))
                    .cornerRadius(12)
                }
              }
              .padding(.horizontal, 16)
              .padding(.vertical, 14)
              .background(Color(hex: "0xFFF3D9"))
              .cornerRadius(12)
            }

            // 连接状态提示
            if let notice = webSocketStore.notice {
              HStack(spacing: 12) {
                Text(notice)
                  .font(.system(size: 16))
                  .foregroundColor(Color(hex: "0x333333"))
                Spacer()
              }
              .padding(.horizontal, 16)
              .padding(.vertical, 14)
              .background(Color(hex: "0xFFF3D9"))
              .cornerRadius(12)
            }

            // NOTICE: 这儿还缺少本地网络权限的提示，但是本地网络权限检测不准确，目前先暂时不要

            if vehiclesStore.vehicles.isEmpty {
              VehicleEmptyView(onTapAdd: { openAddDevice() })
                .padding(.top, 20)
            } else {
              LazyVStack(spacing: 16) {
                ForEach(vehiclesStore.vehicles, id: \.imei) { vehicle in
                  DeviceCardView(
                    vehicle: vehicle,
                    onTapCard: { openDevice(vehicle) }
                  ) { action in
                    handleAction(action, vehicle: vehicle)
                  }
                }
              }
            }

            Spacer(minLength: 40)
          }
          .padding(.horizontal, 20)
          .padding(.bottom, 90)
        }
      }
    }
    .navigationBarHidden(true)
    .navigationBarBackButtonHidden(true)
    .alert(isPresented: $showUnbindAlert) {
      Alert(
        title: Text("提醒"),
        message: Text("确定解绑设备吗？"),
        primaryButton: .default(Text("确定")) {
          let imei = pendingUnbindImei
          if !imei.isEmpty {
            Task {
              await vehiclesStore.unbind(imei: imei)
            }
          }
          pendingUnbindImei = ""
        },
        secondaryButton: .cancel(Text("取消")) {
          pendingUnbindImei = ""
        }
      )
    }
    .onAppear {
      // Step 1. 首次进入刷新设备列表
      if shouldAutoRefresh {
        Task { await vehiclesStore.refresh() }
      }
      locationStore.refresh()
      locationStore.requestIfNeeded()
      localNetworkStore.refresh()
      localNetworkStore.requestIfNeeded()
    }
  }

  private var onlineCountText: String {
    let total = vehiclesStore.vehicles.count
    // let onlineCount = vehiclesStore.vehicles.filter { $0.onlineStatus != 0 }.count
    // if total == 0 { return "暂无设备" }
    // if onlineCount == 0 { return "\(total)台设备离线" }
    // if onlineCount == total { return "\(total)台设备在线运行中" }
    return "已绑定\(total)台设备"
  }

  private func openAddDevice() {
    // Step 1. 进入设备绑定入口（当前为占位页，后续替换为真实二维码/VIN流程）
    appNavigation.push(.qrCodeBind)
  }

  private func handleBindMenuAction(_ action: BindMenuAction) {
    BindingStore.shared.resetStore()

    switch action {
    case .qrcode:
      openAddDevice()
    case .wifi:
      appNavigation.push(.wifiBind)
    case .manual:
      appNavigation.push(.manualBind)
    }
  }

  private func openDevice(_ vehicle: VehicleModel) {
    // Step 2. 进入设备地图/视频页（当前为占位页）
    if vehicle.imei.isEmpty {
      ToastCenter.shared.show("设备信息缺失")
      return
    }
    let entryMode: VehicleLiveEntryMode = isWifiModeEntry(vehicle) ? .wifi : .cellular
    // Wi-Fi 直连模式允许未激活设备进入预览；仅 4G 远程模式需要激活校验
    guard entryMode == .wifi || vehicle.activeStatus == 2 else {
      appNavigation.push(.activeLanding(imei: vehicle.imei, entry: .vehicleLive))
      return
    }
    appNavigation.push(.vehicleLive(deviceId: vehicle.imei, entryMode: entryMode))
  }

  private func isWifiModeEntry(_ vehicle: VehicleModel) -> Bool {
    guard let ssid = vehicle.wifi?.SSID, !ssid.isEmpty else { return false }
    let expected = normalizedSSID(ssid)
    let current = normalizedSSID(WifiStore.shared.currentSSID ?? "")
    guard expected.isEmpty == false, current.isEmpty == false else { return false }
    return expected == current
  }

  private func normalizedSSID(_ value: String) -> String {
    value
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
  }

  private func handleAction(_ action: VehicleQuickAction, vehicle: VehicleModel) {
    // Step 1. 根据入口触发后续路由
    _ = vehicle
    switch action {
    case .cloudService:
      if vehicle.activeStatus == 2 {
        appNavigation.push(.cloudBenefits(imei: vehicle.imei))
      } else {
        appNavigation.push(.activeLanding(imei: vehicle.imei, entry: .cloudService))
      }
    case .cloudAlbum:
      // 跳转到云相册
      appNavigation.push(.cloudAlbum(imei: vehicle.imei))
    case .car:
      // Step 2. 跳转到爱车详情页
      vehiclesStore.setVehicleDetailImei(vehicle.imei)
      // DONE-AI: 详情页直接从 store.currentVehicle 取值
      appNavigation.push(.vehicleDetailCurrent)
    case .more:
      BottomSheetCenter.shared.show {
        EquipmentMoreSheet(
          vehicle: vehicle,
          onAction: { selected in
            BottomSheetCenter.shared.hide()
            handleMoreAction(selected, vehicle: vehicle)
          },
          onCancel: {
            BottomSheetCenter.shared.hide()
          }
        )
      }
    }
  }

  private func handleMoreAction(_ action: VehicleMoreActionView, vehicle: VehicleModel) {
    // Step 1. 处理更多操作
    switch action {
    case .unbind:
      pendingUnbindImei = vehicle.imei
      showUnbindAlert = true
    case .carBrand:
      // 跳转到车辆信息页
      appNavigation.push(.vehicleInfo(imei: vehicle.imei))
    case .settings:
      // 跳转到设置页
      appNavigation.push(.vehicleSettings(imei: vehicle.imei))
    case .wifiDirect:
      guard vehicle.imei.isEmpty == false else {
        ToastCenter.shared.show("设备信息缺失")
        return
      }
      appNavigation.push(.wifiDirect(imei: vehicle.imei))
    case .simCard:
      if let sim = vehicle.sim, !sim.thirdUrl.isEmpty {
        appNavigation.push(.web(url: sim.thirdUrl, title: sim.thirdUrlTitle))
      } else {
        ToastCenter.shared.show("当前设备未配置SIM卡页面")
      }
    }
  }
}
