import SwiftUI
import UIKit

// MARK: - CloudBenefitsView

/// 云服务权益页面
/// 显示设备的云存储、流量、远程播放等权益信息
struct CloudBenefitsView: View {
  // MARK: - Properties

  /// 导航管理模型，用于页面跳转
  private let appNavigation = AppNavigationModel.shared

  /// 车辆数据 store
  @ObservedObject private var vehiclesStore: VehiclesStore = .shared

  /// 云存储弹窗数据（仅页面内使用）
  @State private var cloudModalData: CloudStorageModalData? = nil

  /// 远程播放弹窗数据（仅页面内使用）
  @State private var remotePlaybackModalData: RemotePlaybackModalData? = nil

  // MARK: - Computed Properties

  /// 当前操作的车辆
  var vehicle: VehicleModel? {
    vehiclesStore.currCloudVehicle
  }

  /// 当前设备的有效资源列表（来自车辆缓存）
  private var activeResources: [DeviceResource] {
    vehicle?.cloudBenefitResources ?? []
  }

  /// 是否有基础网联服务
  private var hasBaseService: Bool {
    activeResources.contains { $0.resType == "device" }
  }

  /// 是否有守护服务（OBD 相关）
  private var hasGuardService: Bool {
    activeResources.contains { $0.resType == "obdCar" || $0.resType == "obd" }
  }

  /// 云存储卡片标题
  private var cloudCardTitle: String {
    if let displayedCloudModalData {
      return "\(max(1, displayedCloudModalData.cycleDays))天云存储"
    }
    return "7天云存储"
  }

  /// 远程播放卡片标题
  private var playbackCardTitle: String {
    if let displayedRemotePlaybackModalData {
      return "\(max(0, displayedRemotePlaybackModalData.totalMinutes))分钟播放"
    }
    return "1000分钟直播"
  }

  /// 缓存推导出的云存储弹窗数据（优先用于首屏渲染）
  private var displayedCloudModalData: CloudStorageModalData? {
    if let cloudModalData {
      return cloudModalData
    }
    guard let cloudResource = selectCloudResource(from: activeResources) else { return nil }
    return CloudStorageModalData(
      cycleDays: max(1, Int(cloudResource.total)),
      bars: []
    )
  }

  /// 缓存推导出的远程播放弹窗数据（优先用于首屏渲染）
  private var displayedRemotePlaybackModalData: RemotePlaybackModalData? {
    if let remotePlaybackModalData {
      return remotePlaybackModalData
    }
    guard let summary = aggregateResources(in: activeResources, types: ["live"]) else { return nil }
    return RemotePlaybackModalData(
      leftMinutes: max(0, Int(summary.left)),
      totalMinutes: max(0, Int(summary.total)),
      remainingDays: max(0, daysRemaining(untilMs: summary.endTime))
    )
  }

  /// 是否展示流量卡（按设备 SIM 信息）
  private var shouldShowSimCard: Bool {
    vehicle?.sim?.isXjCard == true
  }

  /// 流量卡标题（按设备 SIM 信息）
  private var simCardTitle: String {
    if let totalFlowString = vehicle?.sim?.totalFlowString, !totalFlowString.isEmpty {
      return "\(totalFlowString)/月流量"
    }
    return "6GB/月流量"
  }

  // MARK: - Body

  var body: some View {
    ZStack {
      VStack(spacing: 0) {
        // 导航栏
        NavHeader(title: "云服务")

        ScrollView {
          VStack(spacing: 24) {
            // Step 1. 基础网联服务卡片
            VStack(alignment: .leading, spacing: 0) {
              HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 8) {
                  Text("基础网联服务")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "0x111111"))

                  HStack(spacing: 8) {
                    Text(vehicle?.activeStatusText ?? "")
                      .font(.system(size: 12, weight: .medium))
                      .foregroundColor(Color(hex: "0x52C41A"))
                      .padding(.horizontal, 6)
                      .padding(.vertical, 2)
                      .background(Color(hex: "0xF6FFED"))
                      .cornerRadius(2)

                    if vehicle?.activeStatus == 2 || vehicle?.activeStatus == 3 {
                      Text("至\(vehicle?.activeTime.prefix(10) ?? "")")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "0x999999"))
                    }
                  }
                }

                Spacer()

                Button {
                  guard let vehicle = vehicle else { return }
                  appNavigation.push(.cloudPlan(imei: vehicle.imei))
                } label: {
                  Text("再次购买")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(ThemeColor.brand500)
                    .cornerRadius(20)
                }
              }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)

            // Step 2. 我的权益卡片网格
            VStack(alignment: .leading, spacing: 16) {
              HStack(spacing: 6) {
                Text("我的权益")
                  .font(.system(size: 18, weight: .bold))
                  .foregroundColor(Color(hex: "0x111111"))

                Text("PRO")
                  .font(.system(size: 10, weight: .bold))
                  .foregroundColor(.white)
                  .padding(.horizontal, 4)
                  .padding(.vertical, 2)
                  .background(Color(hex: "0xFF8D1A"))
                  .cornerRadius(2)

                Spacer()
              }

              // Step 3. 权益卡片列表
              LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                // 基础网联服务卡片
                if hasBaseService {
                  BenefitCard(icon: "icon_service_base", title: "9项车联服务")
                    .onTapGesture {
                      BottomSheetCenter.shared.show(full: true) {
                        ServiceRightsModal(title: "车联服务权益", items: ServiceRightsCatalog.baseServices) {
                          BottomSheetCenter.shared.hide()
                        }
                      }
                    }
                }

                // 爱车守护服务卡片
                if hasGuardService {
                  BenefitCard(icon: "icon_service_obd", title: "8项爱车守护")
                    .onTapGesture {
                      BottomSheetCenter.shared.show(full: true) {
                        ServiceRightsModal(title: "爱车守护权益", items: ServiceRightsCatalog.guardServices) {
                          BottomSheetCenter.shared.hide()
                        }
                      }
                    }
                }

                // 云存储卡片
                if displayedCloudModalData != nil {
                  BenefitCard(icon: "icon_service_cloud", title: cloudCardTitle)
                    .onTapGesture {
                      guard let cloudModalData = displayedCloudModalData else {
                        ToastCenter.shared.show("云存储资源加载中")
                        return
                      }
                      BottomSheetCenter.shared.show(full: true) {
                        CloudStorageModal(data: cloudModalData) {
                          BottomSheetCenter.shared.hide()
                        }
                      }
                    }
                }

                // 流量卡卡片
                if shouldShowSimCard {
                  BenefitCard(icon: "icon_service_sim", title: simCardTitle)
                    .onTapGesture {
                      if let sim = vehicle?.sim, !sim.thirdUrl.isEmpty {
                        appNavigation.push(.web(url: sim.thirdUrl, title: "SIM卡" + sim.thirdUrlTitle))
                      } else {
                        ToastCenter.shared.show("当前设备未配置SIM卡页面")
                      }
                    }
                }

                // 远程播放卡片
                if displayedRemotePlaybackModalData != nil {
                  BenefitCard(icon: "icon_service_live", title: playbackCardTitle)
                    .onTapGesture {
                      guard let remotePlaybackModalData = displayedRemotePlaybackModalData else {
                        ToastCenter.shared.show("远程播放资源加载中")
                        return
                      }
                      BottomSheetCenter.shared.show(full: true) {
                        RemotePlaybackModal(data: remotePlaybackModalData) {
                          BottomSheetCenter.shared.hide()
                        }
                      }
                    }
                }
              }
            }
          }
          .padding(16)
        }
        .background(Color(hex: "0xF8F8F8"))
      }
    }
    .navigationBarHidden(true)
    .ignoresSafeArea()
    // Step 4. 页面首次加载时获取资源数据
    .taskOnce {
      await fetchCloudResourcesIfNeeded(force: false)
    }
    // Step 5. 车辆切换时重新加载资源数据
    .onChange(of: vehicle?.imei ?? "") { _ in
      Task {
        await fetchCloudResourcesIfNeeded(force: true)
      }
    }
  }

  // MARK: - Private Methods

  /// 获取云服务资源数据（如果需要）
  /// - Parameter force: 是否强制刷新
  private func fetchCloudResourcesIfNeeded(force: Bool) async {
    _ = force

    // Step 1. 检查 IMEI 是否有效
    guard let imei = vehicle?.imei, imei.isEmpty == false else {
      print("[CloudBenefits] IMEI 无效，跳过")
      return
    }

    // Step 2. 调用 API 获取设备资源
    let currentResources = await ResourceAPI.shared.getDeviceResource(imei: imei) ?? []

    // Step 4. 解析云存储资源
    let cloudResource = selectCloudResource(from: currentResources)
    let cloudModalData: CloudStorageModalData?
    if let cloudResource {
      // Step 4.1 获取云存储使用量
      let cloudUsageBars = await fetchCloudUsageBars(cycleDays: Int(cloudResource.total))
      cloudModalData = CloudStorageModalData(
        cycleDays: max(1, Int(cloudResource.total)),
        bars: cloudUsageBars
      )
    } else {
      cloudModalData = nil
    }

    // Step 5. 解析远程播放资源
    let playbackResourceSummary = aggregateResources(
      in: currentResources,
      types: ["live"]
    )
    print("[CloudBenefits] 远程播放资源: \(String(describing: playbackResourceSummary))")
    let remotePlaybackModalData = playbackResourceSummary.map { summary in
      RemotePlaybackModalData(
        leftMinutes: max(0, Int(summary.left)),
        totalMinutes: max(0, Int(summary.total)),
        remainingDays: max(0, daysRemaining(untilMs: summary.endTime))
      )
    }

    // Step 6. 更新车辆缓存（页面直接读取缓存，避免重复闪烁）
    await MainActor.run {
      vehiclesStore.updateVehicle(imei: imei) { vehicle in
        vehicle.cloudBenefitResources = currentResources
      }
      self.cloudModalData = cloudModalData
      self.remotePlaybackModalData = remotePlaybackModalData
    }
  }

  /// 从资源列表中选择云存储资源（选择容量最大的）
  /// - Parameter resources: 设备资源列表
  /// - Returns: 云存储资源（容量最大的）
  private func selectCloudResource(from resources: [DeviceResource]) -> DeviceResource? {
    resources
      .filter { $0.resType == "spaceCycle" }
      .max(by: { $0.total < $1.total })
  }

  /// 聚合指定类型的资源
  /// - Parameters:
  ///   - resources: 资源列表
  ///   - types: 要聚合的资源类型集合
  /// - Returns: 聚合后的资源信息（总量、已用、剩余、结束时间）
  private func aggregateResources(
    in resources: [DeviceResource],
    types: Set<String>
  ) -> (total: Int64, used: Int64, left: Int64, endTime: Int64)? {
    // Step 1. 筛选指定类型的资源
    let targets = resources.filter { types.contains($0.resType) }
    guard targets.isEmpty == false else { return nil }

    // Step 2. 聚合计算
    return (
      total: targets.reduce(0) { $0 + $1.total },
      used: targets.reduce(0) { $0 + $1.used },
      left: targets.reduce(0) { $0 + $1.left },
      endTime: targets.map(\.endTime).max() ?? 0
    )
  }

  /// 获取云存储使用量数据
  /// - Parameter cycleDays: 周期天数
  /// - Returns: 每日使用量柱状图数据
  private func fetchCloudUsageBars(cycleDays: Int) async -> [CloudStorageUsageBar] {
    guard let imei = vehicle?.imei, !imei.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      return []
    }

    // Step 1. 计算查询的天数范围
    let days = max(1, min(cycleDays == 0 ? 7 : cycleDays, 30))
    let calendar = Calendar.current
    let today = Date()
    let startDate = calendar.date(byAdding: .day, value: -(days - 1), to: today) ?? today

    // Step 2. 格式化日期
    let queryFormatter = DateFormatter()
    queryFormatter.locale = Locale(identifier: "zh_CN")
    queryFormatter.dateFormat = "yyyy-MM-dd"

    // Step 3. 调用 API 获取使用量
    let usage = await ResourceAPI.shared.getSpaceUsage(
      imei: imei,
      startTime: queryFormatter.string(from: startDate),
      endTime: queryFormatter.string(from: today)
    )

    // Step 4. 按日期统计文件数
    var fileCountByDay: [String: Int] = [:]
    for item in usage ?? [] {
      guard let date = parseSpaceUsageDate(item.date) else { continue }
      let dayKey = queryFormatter.string(from: date)
      fileCountByDay[dayKey] = max(fileCountByDay[dayKey] ?? 0, item.fileCount)
    }

    // Step 5. 生成柱状图数据
    let displayFormatter = DateFormatter()
    displayFormatter.locale = Locale(identifier: "zh_CN")
    displayFormatter.dateFormat = "MM/dd"

    var bars: [CloudStorageUsageBar] = []
    for index in 0 ..< days {
      guard let date = calendar.date(byAdding: .day, value: index, to: startDate) else { continue }
      let dayKey = queryFormatter.string(from: date)
      bars.append(
        CloudStorageUsageBar(
          label: displayFormatter.string(from: date),
          fileCount: fileCountByDay[dayKey] ?? 0
        )
      )
    }
    return bars
  }

  /// 解析空间使用量日期
  /// - Parameter raw: 原始日期字符串
  /// - Returns: 解析后的日期对象
  private func parseSpaceUsageDate(_ raw: String) -> Date? {
    // Step 1. 去除首尾空白
    let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    if normalized.isEmpty { return nil }

    // Step 2. 尝试多种日期格式
    let formats = ["yyyy-MM-dd", "yyyy/MM/dd", "yyyy-MM-dd HH:mm:ss", "yyyy/MM/dd HH:mm:ss", "MM/dd"]

    for format in formats {
      let formatter = DateFormatter()
      formatter.locale = Locale(identifier: "zh_CN")
      formatter.timeZone = TimeZone.current
      formatter.dateFormat = format
      if let date = formatter.date(from: normalized) {
        // Step 3. 如果是 MM/dd 格式，需要补全年份
        if format == "MM/dd" {
          var calendar = Calendar.current
          calendar.timeZone = TimeZone.current
          let year = calendar.component(.year, from: Date())
          let month = calendar.component(.month, from: date)
          let day = calendar.component(.day, from: date)
          return calendar.date(from: DateComponents(year: year, month: month, day: day))
        }
        return date
      }
    }

    return nil
  }

  /// 计算剩余天数
  /// - Parameter endTimeMs: 结束时间（毫秒时间戳）
  /// - Returns: 剩余天数
  private func daysRemaining(untilMs endTimeMs: Int64) -> Int {
    guard endTimeMs > 0 else { return 0 }
    let remainingSeconds = Double(endTimeMs) / 1000 - Date().timeIntervalSince1970
    if remainingSeconds <= 0 { return 0 }
    return Int(ceil(remainingSeconds / 86400))
  }
}

// MARK: - BenefitCard

/// 权益卡片组件
private struct BenefitCard: View {
  let icon: String
  let title: String

  var body: some View {
    VStack(alignment: .leading) {
      Image(icon)
        .resizable()
        .scaledToFit()
        .frame(width: 32, height: 32)
      Spacer()
      Text(title)
        .font(.system(size: 16))
        .foregroundColor(Color(hex: "0x333333"))
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .frame(height: 60)
    .padding(.horizontal, 20)
    .padding(.vertical, 16)
    .background(Color.white)
    .cornerRadius(8)
  }

  // private func isResourceActive(_ resource: DeviceResource, nowMs: Int64) -> Bool {
  //   if resource.effectiveStatus != 1 { return false }
  //   if resource.startTime > 0, resource.startTime > nowMs { return false }
  //   if resource.endTime > 0, resource.endTime < nowMs { return false }
  //   return true
  // }
}
