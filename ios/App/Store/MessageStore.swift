//import Foundation
//import SwiftUI
//import UIKit
//
//// MARK: - MessageStore
//
///// 消息存储管理类
///// 负责消息的同步、存储、已读/未读状态管理
//@MainActor
//final class MessageStore: ObservableObject {
//  // MARK: - Singleton
//
//  static let shared = MessageStore()
//
//  // MARK: - Published Properties
//
//  /// 所有消息列表
//  @Published private(set) var allMessages: [MessageModel] = []
//
//  /// 是否正在同步中
//  @Published private(set) var isSyncing: Bool = false
//
//  /// 错误信息
//  @Published private(set) var errorMessage: String? = nil
//
//  // MARK: - Private Properties
//
//  /// UserDefaults 中保存最后同步时间的前缀 key
//  private let lastUpdateTimeKeyPrefix = "mishu_message_last_update_time"
//
//  /// 行车记录仪消息类型集合
//  private let recorderTypes: Set<String> = ["drive", "event", "recorder"]
//
//  /// 正在处理已读的设备 ID 集合（防止重复触发）
//  private var readingDeviceIds: Set<String> = []
//
//  // MARK: - Initialization
//
//  private init() {
//    // 初始化时从数据库加载所有消息
//    allMessages = MessageTable.fetchAll()
//    updateAppBadgeCount()
//  }
//
//  // MARK: - Public Methods
//
//  /// 重置 store 状态
//  /// 退出登录或需要清空数据时调用
//  func reset() {
//    allMessages = []
//    isSyncing = false
//    errorMessage = nil
//    readingDeviceIds.removeAll()
//    updateAppBadgeCount()
//  }
//
//  /// 从服务器同步最新的消息过来
//  /// Step 1. 检查是否已登录、数据库是否就绪
//  /// Step 2. 获取上次同步时间，调用 API 获取增量消息
//  /// Step 3. 将新消息写入本地数据库
//  /// Step 4. 更新最后同步时间
//  /// Step 5. 重新从数据库加载最新消息列表
//  func syncLatest() async {
//    // Step 1. 判断数据库是否准备好
//    if isSyncing { return }
//    guard SelfStore.shared.isLoggedIn else { return }
//    guard let userId = SelfStore.shared.selfUser?.userId else { return }
//
//    isSyncing = true
//    errorMessage = nil
//    defer { isSyncing = false }
//
//    guard AppDatabase.shared.db != nil else {
//      errorMessage = "数据库未就绪"
//      return
//    }
//
//    // Step 2. 获取最后一次同步的时间 && 同步
//    let lastUpdateTimeKey = "\(lastUpdateTimeKeyPrefix)_\(userId)"
//    let lastUpdateTime = UserDefaults.standard.integer(forKey: lastUpdateTimeKey)
//
//    let result = await MessageAPI.shared.userMessageList(lastUpdateTime)
//    guard let result else {
//      errorMessage = "消息同步失败"
//      return
//    }
//    let remote = result.items
//    do {
//      if !remote.isEmpty {
//        try upsert(remote)
//      }
//    } catch {
//      errorMessage = error.localizedDescription
//      return
//    }
//
//    // Step 3. 写入最后一次同步时间
//    if let windowEnd = result.windowEndUpdateTime, windowEnd > lastUpdateTime {
//      UserDefaults.standard.set(windowEnd, forKey: lastUpdateTimeKey)
//    } else if let maxUpdate = remote.map(\.updateAt).max(), maxUpdate > lastUpdateTime {
//      UserDefaults.standard.set(maxUpdate, forKey: lastUpdateTimeKey)
//    }
//
//    // Step 4. 从数据库加载最新的消息列表
//    withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
//      allMessages = MessageTable.fetchAll()
//    }
//    updateAppBadgeCount()
//  }
//
//  /// 获取指定类型的消息
//  /// - Parameter type: 消息类型（如 "drive", "event" 等）
//  /// - Returns: 该类型的所有消息
//  func messages(ofType type: String) -> [MessageModel] {
//    allMessages.filter { $0.msgType == type }
//  }
//
//  /// 获取所有行车记录仪相关的消息
//  /// 包括 drive、event、recorder 三种类型
//  /// - Returns: 行车记录仪消息列表
//  func recorderMessages() -> [MessageModel] {
//    allMessages.filter { message in
//      guard recorderTypes.contains(message.msgType) else { return false }
//      // 文档定义 11/12 分别是系统/活动消息，避免被误归类到记录仪
//      guard message.typedSubType != .system, message.typedSubType != .campaign else { return false }
//      return true
//    }
//  }
//
//  /// 获取每个设备的最新一条行车记录仪消息
//  /// 用于在消息列表页面展示每个设备的最新消息
//  /// - Returns: 设备 ID -> 最新消息 的字典
//  func lastRecorderMessageByDeviceId() -> [String: MessageModel] {
//    Dictionary(
//      grouping: recorderMessages().compactMap { msg -> (String, MessageModel)? in
//        guard let deviceId = Self.extractDeviceId(from: msg) else { return nil }
//        return (deviceId, msg)
//      },
//      by: { $0.0 }
//    ).compactMapValues { pairs in
//      pairs.map(\.1).max(by: { $0.createAt < $1.createAt })
//    }
//  }
//
//  /// 检查指定设备是否有未读的行车记录仪消息
//  /// 用于在设备列表页面显示小红点
//  /// - Parameter deviceId: 设备 ID
//  /// - Returns: 是否有未读消息
//  func hasUnreadRecorderMessages(deviceId: String) -> Bool {
//    return recorderMessages().contains { message in
//      message.status == 1 && Self.extractDeviceId(from: message) == deviceId
//    }
//  }
//
//  /// 获取所有有未读行车记录仪消息的设备 ID 集合
//  /// - Returns: 未读消息设备 ID 集合
//  func unreadRecorderDeviceIds() -> Set<String> {
//    Set(
//      recorderMessages().compactMap { message in
//        guard message.status == 1 else { return nil }
//        return Self.extractDeviceId(from: message)
//      }
//    )
//  }
//
//  /// 判断单条消息是否应该显示未读红点
//  /// - Parameter message: 消息模型
//  /// - Returns: 是否显示未读红点
//  func shouldShowUnreadDot(for message: MessageModel) -> Bool {
//    message.status == 1
//  }
//
//  /// 获取指定设备的行车记录仪消息
//  /// - Parameter deviceId: 设备 ID
//  /// - Returns: 该设备的所有行车记录仪消息
//  func recorderMessages(deviceId: String) -> [MessageModel] {
//    return recorderMessages().filter { message in
//      Self.extractDeviceId(from: message) == deviceId
//    }
//  }
//
//  /// 进入设备消息列表 2 秒后触发：先上报服务端，再更新本地已读状态
//  /// 延迟 2 秒是为了等用户浏览完消息内容后再标记已读
//  /// Step 1. 防止重复触发（同一个设备只处理一次）
//  /// Step 2. 获取该设备所有未读消息 ID
//  /// Step 3. 延迟 2 秒
//  /// Step 4. 调用 API 批量标记已读
//  /// Step 5. 更新本地数据库和内存状态
//  /// - Parameter deviceId: 设备 ID
//  func markRecorderMessagesAsRead(deviceId: String) async {
//    // Step 1. 防止重复触发
//    guard !readingDeviceIds.contains(deviceId) else { return }
//    readingDeviceIds.insert(deviceId)
//    defer { readingDeviceIds.remove(deviceId) }
//
//    // Step 2. 获取未读消息 ID
//    let unreadIds = recorderMessages(deviceId: deviceId)
//      .filter { $0.status == 1 }
//      .map(\.id)
//      .filter { !$0.isEmpty }
//
//    guard !unreadIds.isEmpty else { return }
//
//    var successIds: [String] = []
//    successIds.reserveCapacity(unreadIds.count)
//
//    // Step 3. 延迟 2 秒
//    try? await Task.sleep(nanoseconds: 2_000_000_000)
//
//    // Step 4. 批量标记消息为已读，调用成功则全部标记为已读
//    _ = await MessageAPI.shared.read(msgIds: unreadIds)
//    successIds = unreadIds
//
//    // Step 5. 更新本地状态
//    guard !successIds.isEmpty else { return }
//    markMessagesAsReadLocally(successIds)
//  }
//
//  /// 删除指定消息
//  /// Step 1. 调用 API 删除服务端消息
//  /// Step 2. 删除本地数据库记录
//  /// Step 3. 更新内存中的消息列表
//  /// - Parameter ids: 要删除的消息 ID 数组
//  func deleteMessages(_ ids: [String]) async {
//    guard !ids.isEmpty else { return }
//
//    // Step 1. Call API
//    _ = await MessageAPI.shared.userDeletePart(ids: ids)
//
//    // Step 2. Update local DB
//    if let db = AppDatabase.shared.db {
//      try? MessageTable.delete(ids, in: db)
//    }
//
//    // Step 3. Update local state
//    withAnimation {
//      allMessages.removeAll { ids.contains($0.id) }
//    }
//    updateAppBadgeCount()
//  }
//
//  /// 标记所有消息为已读
//  /// Step 1. 调用 API 标记服务端所有消息已读
//  /// Step 2. 更新本地数据库
//  /// Step 3. 重新从数据库加载最新消息列表
//  func markAllAsRead() async {
//    // Step 1. Call API
//    _ = await MessageAPI.shared.userReadAll()
//
//    // Step 2. Update local DB
//    if let db = AppDatabase.shared.db {
//      try? MessageTable.markAllAsRead(in: db)
//    }
//
//    // Step 3. Update local state
//    withAnimation {
//      allMessages = MessageTable.fetchAll()
//    }
//    updateAppBadgeCount()
//  }
//
//  // MARK: - Private Methods
//
//  /// 将消息批量写入数据库（存在则更新，不存在则插入）
//  /// - Parameter messages: 消息模型数组
//  private func upsert(_ messages: [MessageModel]) throws {
//    guard let db = AppDatabase.shared.db else { return }
//    try MessageTable.upsert(messages, in: db)
//  }
//
//  /// 从消息模型中提取设备 ID
//  /// 优先使用 imei 字段，如果为空则从 schema 中解析
//  /// - Parameter message: 消息模型
//  /// - Returns: 设备 ID，可能为空
//  static func extractDeviceId(from message: MessageModel) -> String? {
//    if !message.imei.isEmpty { return message.imei }
//    return extractDeviceId(from: message.schema)
//  }
//
//  /// 从 URL schema 字符串中解析设备 ID
//  /// 支持多种 key：deviceId、device_id、imei
//  /// 优先使用 URLComponents 解析 query 参数
//  /// 如果解析不到，则使用正则表达式查找 15 位数字（IMEI 格式）
//  /// - Parameter rawSchema: URL schema 字符串
//  /// - Returns: 解析出的设备 ID，可能为空
//  static func extractDeviceId(from rawSchema: String) -> String? {
//    // Step 1. 检查 schema 是否为空
//    guard !rawSchema.isEmpty else { return nil }
//
//    // Step 2. 尝试使用 URLComponents 解析 query 参数
//    if let components = URLComponents(string: rawSchema), let items = components.queryItems {
//      for key in ["deviceId", "device_id", "imei"] {
//        if let value = items.first(where: { $0.name == key })?.value,
//           !value.isEmpty
//        {
//          return value
//        }
//      }
//    }
//
//    // Step 3. 手动解析 key=value 格式
//    let candidates: [String] = ["deviceId", "device_id", "imei"]
//    for key in candidates {
//      let token = "\(key)="
//      if let range = rawSchema.range(of: token) {
//        let tail = rawSchema[range.upperBound...]
//        let value = tail.split(whereSeparator: { $0 == "&" || $0 == "#" || $0 == "?" || $0 == "/" }).first ?? ""
//        let stringValue = String(value)
//        if !stringValue.isEmpty { return stringValue }
//      }
//    }
//
//    // Step 4. 使用正则表达式查找 15 位数字（IMEI 格式）
//    if let regex = try? NSRegularExpression(pattern: #"\b\d{15}\b"#) {
//      let ns = rawSchema as NSString
//      if let match = regex.firstMatch(in: rawSchema, range: NSRange(location: 0, length: ns.length)) {
//        return ns.substring(with: match.range)
//      }
//    }
//
//    return nil
//  }
//
//  /// 本地批量标记消息为已读
//  /// Step 1. 将 ID 数组转为 Set 去重
//  /// Step 2. 遍历消息列表，将匹配的消息状态改为已读
//  /// Step 3. 更新数据库
//  /// - Parameter ids: 消息 ID 数组
//  private func markMessagesAsReadLocally(_ ids: [String]) {
//    // Step 1. 去重
//    let idSet = Set(ids.filter { !$0.isEmpty })
//    guard !idSet.isEmpty else { return }
//
//    // Step 2. 更新内存状态
//    var hasChanges = false
//    let updated = allMessages.map { message in
//      guard idSet.contains(message.id), message.status == 1 else { return message }
//      hasChanges = true
//      return message.updatingStatus(2)
//    }
//    guard hasChanges else { return }
//
//    // Step 3. 更新数据库
//    allMessages = updated
//    if let db = AppDatabase.shared.db {
//      try? MessageTable.markAsRead(Array(idSet), in: db)
//    }
//    updateAppBadgeCount()
//  }
//
//  /// 将当前未读消息数同步到系统桌面 App 角标
//  private func updateAppBadgeCount() {
//    let unreadCount = allMessages.reduce(into: 0) { partialResult, message in
//      if message.status == 1 { partialResult += 1 }
//    }
//    UIApplication.shared.applicationIconBadgeNumber = unreadCount
//  }
//}
