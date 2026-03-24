import Foundation

// DONE-AI: 已改为强类型返回

final class SettingAPI {
  static let shared = SettingAPI()

  let client: APIClient

  private init(client: APIClient = APIClient()) {
    self.client = client
  }

  func getTemplateData(imei: String) async -> SettingTemplateData? {
    // Step 1. 拉取模板数据
    guard var data: SettingTemplateData = await client.postRequest(
      "/v4/u/setting/getTemplate", AnyParams(["imei": imei]), true, false
    ) else {
      return nil
    }

    // Step 2. 为所有 group 类型补齐默认 c 字段（避免渲染 ForEach(id: \.c) 出现 nil/重复）
    // DONE-AI: 规则：c = group-{level}-{index}
    Self.fillMissingGroupC(items: &data.template, level: 0)

    // Step 3. 返回处理后的模板数据
    return data
  }

  private static func fillMissingGroupC(items: inout [TemplateItem], level: Int) {
    // Step 1. 遍历同层 items，根据 index 生成稳定 id
    for index in items.indices {
      // Step 2. 仅对 group 且 c 为空的节点补齐
      if items[index].type == "group" {
        let existing = items[index].c?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if existing.isEmpty {
          items[index].c = "group-\(level)-\(index)"
        }
      }

      // Step 3. 递归处理子节点（folder / group 的 payload.items）
      guard let payload = items[index].payload else { continue }
      switch payload {
      case var .folder(folder):
        if var children = folder.items, !children.isEmpty {
          fillMissingGroupC(items: &children, level: level + 1)
          folder.items = children
          items[index].payload = .folder(folder)
        }
      case var .group(group):
        if var children = group.items, !children.isEmpty {
          fillMissingGroupC(items: &children, level: level + 1)
          group.items = children
          items[index].payload = .group(group)
        }
      default:
        break
      }
    }
  }

  func queryBackendSetting(imei: String) async -> [SettingBackendData]? {
    return await client.postRequest(
      "/v4/u/setting/queryBackendSetting", AnyParams(["imei": imei]), true, false
    )
  }

  func queryDeviceSetting(imei: String) async -> [SettingBackendData]? {
    return await client.postRequest(
      "/v4/u/setting/queryDeviceSetting", AnyParams(["imei": imei]), true, false
    )
  }

  func setBackendSettings(imei: String, action: String, params: String) async -> [SettingBackendData]? {
    let startAt = Date()
    let result: [SettingBackendData]? = await client.postRequest(
      "/v4/u/setting/setBackendSettings", AnyParams([
        "imei": imei,
        "action": action,
        "params": params,
      ]), true, false
    )
    await ensureMinimumSettingDuration(startAt: startAt)
    return result
  }

  /// 远程控制设备 Wi-Fi 开关（`enabled=true` 打开，`false` 关闭）。
  func setRemoteWifiSwitch(imei: String, enabled: Bool) async -> Bool {
    let params = enabled ? "1" : "0"
    let patch = await setDeviceSettings(imei: imei, action: "wifi_switch", params: params)
    return patch != nil
  }

  /// 设备设置接口使用 action/params
  func setDeviceSettings(imei: String, action: String, params: String) async -> [SettingBackendData]? {
    let startAt = Date()
    let payload = AnyParams([
      "imei": imei,
      "action": action,
      "params": params,
    ])
    let result: [SettingBackendData]? = await client.postRequest(
      "/v4/u/setting/setDeviceSettings", payload, true, false
    )
    await ensureMinimumSettingDuration(startAt: startAt)
    return result
  }

  /// 设置接口最小耗时保护：避免返回过快导致“像 bug 一样闪一下”
  private func ensureMinimumSettingDuration(startAt: Date, minimumMilliseconds: Double = 500) async {
    let elapsed = Date().timeIntervalSince(startAt) * 1000
    guard elapsed < minimumMilliseconds else { return }

    let remainMs = minimumMilliseconds - elapsed
    let remainNs = UInt64(remainMs * 1_000_000)
    try? await Task.sleep(nanoseconds: remainNs)
  }

  func queryGpsInfo(imei: String) async -> [SettingRemoteQueryItem]? {
    let payload = AnyParams([
      "imei": imei,
      "action": "GPS",
      "params": "QUERY",
    ])
    return await client.postRequest(
      "/v4/u/setting/setDeviceSettings", payload, true, false
    )
  }

  // func setPoliceStatus(imei: String, status: Int) async throws -> Empty? {
  //   let payload = AnyParams([
  //     "imei": AnyEncodable(imei),
  //     "status": AnyEncodable(status),
  //   ])
  //   return try await client.request(
  //     .Post, "/v4/u/setting/setPoliceStatus", payload
  //   )
  // }

  // func ability() async throws -> SettingAbilityData? {
  //   try await client.request(
  //     .Post, "/v4/u/setting/ability"
  //   )
  // }

  // func getSettingsReason() async throws -> SettingReasonData? {
  //   try await client.request(
  //     .Post, "/v4/u/setting/getSettingsReason"
  //   )
  // }

  // func setCloudStatus(imei: String, status: Int) async throws -> Empty? {
  //   let payload = AnyParams([
  //     "imei": AnyEncodable(imei),
  //     "status": AnyEncodable(status),
  //   ])
  //   return try await client.request(
  //     .Post, "/v4/u/setting/setCloudStatus", payload
  //   )
  // }

  // func queryObdSetting(imei: String) async throws -> SettingOBDSettingData? {
  //   try await client.request(
  //     .Post, "/v4/u/setting/queryObdSetting", AnyParams(["imei": imei])
  //   )
  // }
}

struct SettingAbilityData: Decodable {}

struct SettingReasonData: Decodable {}

// DONE-AI: 删除仅包含 imei 的 payload struct，直接传字典即可

// 设置模板说明
// c: string，设置项唯一的key，为了减少包传输体积去替换以前的cmd设置
// v: string, 当前设置项的值
// s: string, 0-不可设置 1-可设置，仅显示的控件不可设置的状态下不需要变灰
// r: string,  不可设置码，设备端返回一个数字，前端根据数字显示提示语
// e: string,    错误码，设备端返回一个数字，前端根据数字显示提示语
// cmd: string, 以前设置项唯一的key，为了保持兼容，所以需要保留
// item: string, 设置项中文标题
// special: string, 标题后的蓝色字体
// describe: string, 描述
// type: string, 设置项类别，如：列表、单选、开关
// source: string, 标识设置项归属于后台还是设备
// list: array, 可选择的设置，0-程序执行的内容 1-用户看到的内容 2-选项描述  3-选项长度
// display: int,    0-有子项则显示 1-强制显示（目前仅文件夹类型需要用到） 2-用户端强制不显示
// operate: int, 字段不存在或0-无操作，1-复制 2-确认操作提醒
// confirmPrompt: []string, 确认操作提示语，每个选项都可以单独确认操作提示语，假如提示语只有一个，则所有选项都是这个提示语
// color: 字体颜色，button类型改变button内部的文字颜色，readonly类型改变仅读文字颜色
// unit: []string, 单位，第一位 倍率，第二位单位，例：[0.01, "v"]
// threshold: int,    阈值，低/高于阈值变红，和控件progress_***配合使用
// struct SettingTemplateV2Data: Decodable {
//   let reason: [SettingTemplateReason]?
//   let template: [SettingTemplateGroup]?
// }

struct SettingTemplateReason: Decodable {
  let appPath: String?
  let msg: String?
  let r: String?
  let type: String?
  let params: [String: String]?

  private enum CodingKeys: String, CodingKey {
    case appPath
    case msg
    case r
    case type
    case params
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    appPath = try? container.decodeIfPresent(String.self, forKey: .appPath)
    msg = try? container.decodeIfPresent(String.self, forKey: .msg)
    r = try? container.decodeIfPresent(String.self, forKey: .r)
    type = try? container.decodeIfPresent(String.self, forKey: .type)

    if let raw = try? container.decodeIfPresent([String: String].self, forKey: .params) {
      params = raw
    } else if let raw = try? container.decodeIfPresent([String: Int].self, forKey: .params) {
      params = raw.mapValues { String($0) }
    } else if let raw = try? container.decodeIfPresent([String: Double].self, forKey: .params) {
      params = raw.mapValues { String($0) }
    } else if let raw = try? container.decodeIfPresent([String: Bool].self, forKey: .params) {
      params = raw.mapValues { $0 ? "1" : "0" }
    } else if let raw = try? container.decodeIfPresent([String: AnyString].self, forKey: .params) {
      params = raw.mapValues(\.value)
    } else {
      params = nil
    }
  }
}

// struct SettingTemplateGroup: Decodable {
//   let c: String?
//   let item: String?
//   let type: String?
//   let cornerType: Int?
//   let source: String?
//   let mustShow: Bool?
//   let icon: String?
//   let itemList: [SettingTemplateItem]?
//   let folderShow: Int?
//   let display: Int?
// }

struct SettingTemplateItem: Decodable {
  let c: String?
  let cmd: String?
  let item: String?
  let type: String?
  let source: String?
  let progressLeft: String?
  let progressRight: String?
  let list: [[String]]?
  let value: String?
  let set: String?
  let show: Int?
  let r: String?
  let describe: String?
  let special: String?
  let threshold: Int?
  let operate: Int?
  let confirmPrompt: [String]?
  let color: String?
  let unit: [String]?

  private enum CodingKeys: String, CodingKey {
    case c
    case cmd
    case item
    case type
    case source
    case progressLeft
    case progressRight
    case list
    case value
    case set
    case show
    case r
    case describe
    case special
    case threshold
    case operate
    case confirmPrompt
    case color
    case unit
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    c = try? container.decodeIfPresent(String.self, forKey: .c)
    cmd = try? container.decodeIfPresent(String.self, forKey: .cmd)
    item = try? container.decodeIfPresent(String.self, forKey: .item)
    type = try? container.decodeIfPresent(String.self, forKey: .type)
    source = try? container.decodeIfPresent(String.self, forKey: .source)
    progressLeft = try? container.decodeIfPresent(String.self, forKey: .progressLeft)
    progressRight = try? container.decodeIfPresent(String.self, forKey: .progressRight)

    if let raw = try? container.decodeIfPresent([[String]].self, forKey: .list) {
      list = raw
    } else if let raw = try? container.decodeIfPresent([[AnyString]].self, forKey: .list) {
      list = raw.map { $0.map(\.value) }
    } else if let raw = try? container.decodeIfPresent([[Int]].self, forKey: .list) {
      list = raw.map { $0.map { String($0) } }
    } else if let raw = try? container.decodeIfPresent([[Double]].self, forKey: .list) {
      list = raw.map { $0.map { String($0) } }
    } else {
      list = nil
    }

    value = SettingDecoding.decodeString(container, key: .value)
    set = SettingDecoding.decodeString(container, key: .set)
    show = SettingDecoding.decodeInt(container, key: .show)
    r = SettingDecoding.decodeString(container, key: .r)
    describe = SettingDecoding.decodeString(container, key: .describe)
    special = SettingDecoding.decodeString(container, key: .special)
    threshold = SettingDecoding.decodeInt(container, key: .threshold)
    operate = SettingDecoding.decodeInt(container, key: .operate)
    confirmPrompt = (try? container.decodeIfPresent([String].self, forKey: .confirmPrompt))
    color = SettingDecoding.decodeString(container, key: .color)

    if let raw = try? container.decodeIfPresent([String].self, forKey: .unit) {
      unit = raw
    } else if let raw = try? container.decodeIfPresent([AnyString].self, forKey: .unit) {
      unit = raw.map(\.value)
    } else if let raw = try? container.decodeIfPresent([Double].self, forKey: .unit) {
      unit = raw.map { String($0) }
    } else if let raw = try? container.decodeIfPresent([Int].self, forKey: .unit) {
      unit = raw.map { String($0) }
    } else {
      unit = nil
    }
  }
}

struct SettingBackendData: Decodable {
  let c: String? // 唯一标识
  let v: String? // value，真实的值是多少
  let s: String? // 是否支持，1支持，0不支持
  let l: [String]? // 支持选择的列表
  let r: String? // 不支持设置时原因，对应reason模板

  private enum CodingKeys: String, CodingKey {
    case c
    case v
    case s
    case l
    case r
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    c = try? container.decodeIfPresent(String.self, forKey: .c)
    v = SettingDecoding.decodeString(container, key: .v)
    // 注意：增量更新接口经常不返回 s，不能默认成 "0"，否则会把已有支持状态错误覆盖为不支持。
    // s = SettingDecoding.decodeString(container, key: .s)
    s = container.safeDecodeString(.s, "1") // 设备没有返回，就默认是1
    // s = SettingDecoding.decodeString(container, key: .s)
    // 注意：增量更新接口经常不返回 s，不能默认成 "0"，否则会把已有支持状态错误覆盖为不支持。
    r = SettingDecoding.decodeString(container, key: .r)

    if let raw = try? container.decodeIfPresent([String].self, forKey: .l) {
      l = raw
    } else if let raw = try? container.decodeIfPresent([Int].self, forKey: .l) {
      l = raw.map { String($0) }
    } else if let raw = try? container.decodeIfPresent([Double].self, forKey: .l) {
      l = raw.map { String($0) }
    } else if let raw = try? container.decodeIfPresent([AnyString].self, forKey: .l) {
      l = raw.map(\.value)
    } else {
      l = nil
    }
  }
}

extension SettingBackendData {
  init(c: String?, v: String?, s: String?, l: [String]?, r: String?) {
    self.c = c
    self.v = v
    self.s = s
    self.l = l
    self.r = r
  }

  func merged(with patch: SettingBackendData) -> SettingBackendData {
    SettingBackendData(
      c: patch.c ?? c,
      v: patch.v ?? v,
      s: patch.s ?? s,
      l: patch.l ?? l,
      r: patch.r ?? r
    )
  }
}

/// 目前这个看上去就是GPS在用，我在想，难道这个不能使用查询服务器那个吗？后续要花时间研究下能不能合并！
struct SettingRemoteQueryItem: Decodable {
  let c: String?
  let v: String?
  let e: String?
  let r: String?

  private enum CodingKeys: String, CodingKey {
    case c
    case v
    case e
    case r
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    c = try? container.decodeIfPresent(String.self, forKey: .c)
    v = SettingDecoding.decodeString(container, key: .v)
    e = SettingDecoding.decodeString(container, key: .e)
    r = SettingDecoding.decodeString(container, key: .r)
  }
}

private enum SettingDecoding {
  static func decodeString<K: CodingKey>(_ container: KeyedDecodingContainer<K>, key: K) -> String? {
    if let value = try? container.decodeIfPresent(String.self, forKey: key) {
      return value
    }
    if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
      return String(value)
    }
    if let value = try? container.decodeIfPresent(Double.self, forKey: key) {
      return String(value)
    }
    if let value = try? container.decodeIfPresent(Bool.self, forKey: key) {
      return value ? "1" : "0"
    }
    return nil
  }

  static func decodeInt<K: CodingKey>(_ container: KeyedDecodingContainer<K>, key: K) -> Int? {
    if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
      return value
    }
    if let value = try? container.decodeIfPresent(Double.self, forKey: key) {
      return Int(value)
    }
    if let value = try? container.decodeIfPresent(String.self, forKey: key) {
      return Int(value)
    }
    if let value = try? container.decodeIfPresent(Bool.self, forKey: key) {
      return value ? 1 : 0
    }
    return nil
  }
}

private struct AnyString: Decodable {
  let value: String

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let value = try? container.decode(String.self) {
      self.value = value
      return
    }
    if let value = try? container.decode(Int.self) {
      self.value = String(value)
      return
    }
    if let value = try? container.decode(Double.self) {
      self.value = String(value)
      return
    }
    if let value = try? container.decode(Bool.self) {
      self.value = value ? "1" : "0"
      return
    }
    value = ""
  }
}

struct SettingOBDSettingData: Decodable {}
