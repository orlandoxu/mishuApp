import SwiftUI

// MARK: - MessageView

/// 消息中心页面
/// 展示三类消息：记录仪消息、活动消息、系统消息
struct MessageView: View {
  private struct UnboundRecorderEntry: Identifiable {
    let deviceId: String
    let lastMessage: MessageModel

    var id: String {
      deviceId
    }
  }

  // MARK: - Properties

  private let appNavigation = AppNavigationModel.shared

  /// 当前选中的 Tab
  @State private var selectedTab: MessageTabType = .recorder

  /// 消息数据管理
  @ObservedObject private var store: MessageStore = .shared

  /// 车辆数据管理
  @StateObject private var vehiclesStore: VehiclesStore = .shared

  /// 缓存 safeAreaTop 值，防止滚动时重新计算导致变化
  @State private var cachedSafeAreaTop: CGFloat = 0

  // MARK: - Private Properties

  /// 绑定时间格式化器（用于将绑定时间字符串转换为时间戳）
  private static let bindTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return formatter
  }()

  /// 最后一条记录仪消息（按设备 ID 分组）
  private var lastRecorderMessageByDevice: [String: MessageModel] {
    store.lastRecorderMessageByDeviceId()
  }

  /// 有记录仪消息的车辆列表（按绑定时间倒序）
  private var recorderVehicles: [VehicleModel] {
    let vehicles = vehiclesStore.vehicles

    let filtered = vehicles.filter { vehicle in
      lastRecorderMessageByDevice[normalizeDeviceId(vehicle.imei)] != nil
    }

    return filtered.sorted { lhs, rhs in
      bindTimestamp(lhs) > bindTimestamp(rhs)
    }
  }

  /// 已解绑设备的记录仪消息（按最后消息时间倒序）
  private var unboundRecorderEntries: [UnboundRecorderEntry] {
    let boundIds = Set(vehiclesStore.vehicles.map { normalizeDeviceId($0.imei) })
    let entries = lastRecorderMessageByDevice.compactMap { deviceId, message -> UnboundRecorderEntry? in
      guard !deviceId.isEmpty else { return nil }
      guard !boundIds.contains(deviceId) else { return nil }
      return UnboundRecorderEntry(deviceId: deviceId, lastMessage: message)
    }
    return entries.sorted { $0.lastMessage.updateAt > $1.lastMessage.updateAt }
  }

  /// 活动消息列表
  private var activityMessages: [MessageModel] {
    store.allMessages.filter {
      $0.typedSubType == .campaign || $0.msgType == "campaign" || $0.msgType == "activity"
    }
  }

  /// 系统消息列表
  private var systemMessages: [MessageModel] {
    store.allMessages.filter {
      $0.typedSubType == .system || $0.msgType == "system"
    }
  }

  // MARK: - Private Methods

  /// 是否需要显示 Empty 占位
  /// - Parameter tab: 消息 Tab 类型
  /// - Returns: 是否显示空状态
  private func shouldShowEmpty(in tab: MessageTabType) -> Bool {
    switch tab {
    case .recorder: return recorderVehicles.isEmpty && unboundRecorderEntries.isEmpty
    case .activity: return activityMessages.isEmpty
    case .system: return systemMessages.isEmpty
    }
  }

  private func normalizeDeviceId(_ raw: String) -> String {
    raw.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  /// 获取车辆的绑定时间戳（用于排序）
  /// - Parameter vehicle: 车辆模型
  /// - Returns: 绑定时间戳（毫秒）
  private func bindTimestamp(_ vehicle: VehicleModel) -> Int {
    let raw = vehicle.bindTime.trimmingCharacters(in: .whitespacesAndNewlines)
    if raw.isEmpty { return 0 }
    if let value = Int(raw) { return value }
    if let date = Self.bindTimeFormatter.date(from: raw) {
      return Int(date.timeIntervalSince1970)
    }
    return 0
  }

  // MARK: - Body

  var body: some View {
    VStack(spacing: 0) {
      // 顶部安全区域占位
      Spacer().frame(height: cachedSafeAreaTop).background(Color.white)

      // Tab 切换栏
      MessageTabs(selectedTab: $selectedTab)

      // Tab 内容区
      TabView(selection: $selectedTab) {
        // 记录仪消息
        recorderTabContent.tag(MessageTabType.recorder)

        // 活动消息
        activityTabContent
          .tag(MessageTabType.activity)

        // 系统消息
        systemTabContent
          .tag(MessageTabType.system)
      }
      .tabViewStyle(.page(indexDisplayMode: .never))
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color(hex: "0xF8F8F8"))
    }
    .ignoresSafeArea(edges: .top)
    .background(Color.white)
    .navigationBarHidden(true)
    .onAppear {
      // 缓存 safeAreaTop 值，只计算一次
      cachedSafeAreaTop = UIApplication.shared.windows.first?.safeAreaInsets.top ?? 47
      // 页面出现时，如果已登录则同步数据
      Task {
        if SelfStore.shared.isLoggedIn {
          if vehiclesStore.vehicles.isEmpty {
            await vehiclesStore.refresh()
          }
          await store.syncLatest()
        }
      }
    }
  }

  // MARK: - Tab Contents

  /// 记录仪消息 Tab 内容
  private var recorderTabContent: some View {
    ScrollView {
      VStack(spacing: 12) {
        // “已绑定设备”分组
        if !recorderVehicles.isEmpty {
          Text("已绑定设备")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(Color(hex: "0x999999"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 2)

          ForEach(recorderVehicles, id: \.imei) { vehicle in
            let deviceId = normalizeDeviceId(vehicle.imei)
            let carLicense = vehicle.car?.carLicense.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            // 标题优先使用车牌号，其次昵称，最后 IMEI
            let displayTitle = carLicense.isEmpty ? (vehicle.nickname.isEmpty ? vehicle.imei : vehicle.nickname) : carLicense
            // 图片优先级：车辆图标 > 缩略图 > Logo
            let image =
              vehicle.car?.markImgUrl.isEmpty == false
                ? (vehicle.car?.markImgUrl ?? "")
                : (vehicle.thumbnail.isEmpty
                  ? (vehicle.logoUrl.isEmpty ? (vehicle.car?.carIcon ?? "") : vehicle.logoUrl)
                  : vehicle.thumbnail)

            let last = lastRecorderMessageByDevice[deviceId]
            let content = last?.title ?? ""
            let timeText = Date.messageRelativeTimeText(from: last?.createAt ?? 0)

            // 点击跳转到该设备的记录仪消息列表
            Button {
              appNavigation.push(.messageRecorderMessageList(deviceId: deviceId, title: displayTitle))
            } label: {
              VehicleFolder(
                imageUrl: image,
                title: displayTitle,
                content: content,
                time: timeText,
                hasUnread: store.hasUnreadRecorderMessages(deviceId: deviceId)
              )
            }
            .buttonStyle(.plain)
          }
        }

        if !unboundRecorderEntries.isEmpty {
          Text("已解绑设备")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(Color(hex: "0x999999"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, recorderVehicles.isEmpty ? 2 : 8)

          ForEach(unboundRecorderEntries) { entry in
            let deviceId = entry.deviceId
            let displayTitle = "设备 ****\(deviceId.suffix(4))"
            let content = entry.lastMessage.title
            let timeText = Date.messageRelativeTimeText(from: entry.lastMessage.createAt)

            Button {
              appNavigation.push(.messageRecorderMessageList(deviceId: deviceId, title: displayTitle))
            } label: {
              VehicleFolder(
                imageUrl: "",
                title: displayTitle,
                content: content,
                time: timeText,
                hasUnread: store.hasUnreadRecorderMessages(deviceId: deviceId)
              )
            }
            .buttonStyle(.plain)
          }
        }
        Spacer().frame(height: 120)
      }
      .padding(16)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(shouldShowEmpty(in: .recorder) ? Color.clear : Color(hex: "0xF8F8F8"))
    .overlay(
      shouldShowEmpty(in: .recorder) ? MessageEmptyView(title: "还没有记录仪消息") : nil
    )
  }

  /// 活动消息 Tab 内容
  private var activityTabContent: some View {
    ScrollView {
      LazyVStack(spacing: 12) {
        ForEach(activityMessages, id: \.id) { item in
          MessageCell(
            message: item,
            time: Date.messageRelativeTimeText(from: item.updateAt),
            hasUnread: store.shouldShowUnreadDot(for: item)
          )
        }
      }
      .padding(16)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(shouldShowEmpty(in: .activity) ? Color.clear : Color(hex: "0xF8F8F8"))
    .overlay(
      shouldShowEmpty(in: .activity) ? MessageEmptyView(title: "还没有收到活动消息") : nil
    )
  }

  /// 系统消息 Tab 内容
  private var systemTabContent: some View {
    ScrollView {
      LazyVStack(spacing: 12) {
        ForEach(systemMessages, id: \.id) { item in
          MessageCell(
            message: item,
            time: Date.messageRelativeTimeText(from: item.updateAt),
            hasUnread: store.shouldShowUnreadDot(for: item)
          )
        }
      }
      .padding(16)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(shouldShowEmpty(in: .system) ? Color.clear : Color(hex: "0xF8F8F8"))
    .overlay(
      shouldShowEmpty(in: .system) ? MessageEmptyView(title: "还没有收到系统消息") : nil
    )
  }
}
