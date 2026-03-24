import Foundation

// DONE-AI: 漏了一个Folder。我抓包如下：
// {"c":"17","icon":"settings_tts","item":"语音命令","payload":{"items":[{"c":"","item":"","payload":{"items":[{"c":"134","cmd":"voice","item":"语音命令","source":"backend","type":"voice_type"}]},"type":"group"}]},"source":"backend","type":"folder"}
// 有一个语音命令的folder，点进去之后其实是一个非常特殊的页面（目前是写死的页面）
// 所以我需要你，先根据c = 17，来判断是这个文件夹，点击进去之后，直接进入到一个特殊的，单独写的页面就行了。
// 页面的UI我放在：uiPng/设置项UI截图/语音命令页面的UI.png
// 注意，这个页面，整个都是一个静态页面！这个页面是一定要显示的。
// DONE-AI: 但是目前不知道为啥，我没有看到这个folder渲染出来。是不是因为你判断了show的原因啊？是这样的，这个folder，目前直接写死，直接强制要显示！

struct ProgressPayload: Decodable, Hashable {
  let min: Int?
  let max: Int?
  let minDesc: String?
  let maxDesc: String?
  let asc: Bool?
}

/// progress_split，这个目前单独定义了一个(因为时空流要改文案)
struct ProgressSplitPayload: Decodable, Hashable {
  let min: Int?
  let max: Int?
}

struct FolderPayload: Decodable, Hashable {
  var items: [TemplateItem]?
}

struct GroupPayload: Decodable, Hashable {
  var items: [TemplateItem]?
}

struct RadioPayload: Decodable, Hashable {
  struct Item: Decodable, Hashable {
    let k: String?
    let v: String?
    let desc: String?
    let width: Int?
  }

  let items: [Item]?
}

struct SwitchPayload: Decodable, Hashable {
  let falseVal: String?
  let trueVal: String?
}

struct StringPayload: Decodable, Hashable {
  let v: String?
}

struct IntPayload: Decodable, Hashable {
  let v: Int?
}

struct InputPayload: Decodable, Hashable {
  let copy: Bool?
}

struct PasswordPayload: Decodable, Hashable {
  let copy: Bool?
}

struct GpsPayload: Decodable, Hashable {}

struct GpsSatelliteInfo: Hashable {
  let number: Int
  let signal: Int
}

struct GpsInfo: Hashable {
  let isLocated: Bool
  let latitude: Double
  let longitude: Double
  let speed: Double
  let satellites: [GpsSatelliteInfo]

  static let empty = GpsInfo(isLocated: false, latitude: 0, longitude: 0, speed: 0, satellites: [])
}

struct ButtonPayload: Decodable, Hashable {
  let copy: Bool?
  let confirmPrompt: String?
  let color: String?
}

struct ReadonlyPayload: Decodable, Hashable {
  struct Unit: Decodable, Hashable {
    let mul: Double?
    let unit: String?
  }

  let copy: Bool?
  let unit: Unit?
  let color: String?
}

struct TimeWindowPayload: Decodable, Hashable {
  let min: Int?
  let max: Int?
}

struct StoragePayload: Decodable, Hashable {
  var items: [TemplateItem]?
}

struct SysNotifyPayload: Decodable, Hashable {}
struct LogoPayload: Decodable, Hashable {}

// DONE-AI: space 不再作为 payload 类型参与解码，仅保留 type 用于列表间距
struct OrderPayload: Decodable, Hashable {}

enum TemplatePayloadEnum: Hashable {
  case progress(ProgressPayload)
  case progressSplit(ProgressSplitPayload)
  case folder(FolderPayload)
  case group(GroupPayload)
  case radio(RadioPayload)
  case string(StringPayload)
  case int(IntPayload)
  case switchValue(SwitchPayload)
  case input(InputPayload)
  case password(PasswordPayload)
  case gps(GpsPayload)
  case button(ButtonPayload)
  case readonly(ReadonlyPayload)
  case timeWindow(TimeWindowPayload)
  case storage(StoragePayload)
  case sysNotify(SysNotifyPayload)
  case logo(LogoPayload)
  case order(OrderPayload)
}

struct TemplateItem: Decodable, Hashable {
  var c: String?
  let cmd: String?
  let item: String?
  let type: String
  let icon: String?
  let source: String?
  let show: Int? // 显示控制。0：不支持就隐藏, 1:不支持变灰, 2: 强制显示, 默认0
  let describe: String?
  var payload: TemplatePayloadEnum?

  private enum CodingKeys: String, CodingKey {
    case c
    case cmd
    case item
    case type
    case icon
    case source
    case show
    case describe
    case payload
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    c = try container.decodeIfPresent(String.self, forKey: .c)
    cmd = try container.decodeIfPresent(String.self, forKey: .cmd)
    item = try container.decodeIfPresent(String.self, forKey: .item)
    type = (try? container.decode(String.self, forKey: .type)) ?? ""
    icon = try container.decodeIfPresent(String.self, forKey: .icon)
    source = try container.decodeIfPresent(String.self, forKey: .source)
    show = try container.decodeIfPresent(Int.self, forKey: .show)
    describe = try container.decodeIfPresent(String.self, forKey: .describe)

    switch type {
    case "folder":
      if let value = try? container.decode(FolderPayload.self, forKey: .payload) {
        payload = .folder(value)
      } else {
        payload = nil
      }
    case "group":
      if let value = try? container.decode(GroupPayload.self, forKey: .payload) {
        payload = .group(value)
      } else {
        payload = nil
      }
    case "switch":
      if let value = try? container.decode(SwitchPayload.self, forKey: .payload) {
        payload = .switchValue(value)
      } else {
        payload = nil
      }
    case "radio":
      if let value = try? container.decode(RadioPayload.self, forKey: .payload) {
        payload = .radio(value)
      } else {
        payload = nil
      }
    case "progress", "progress_low", "progress_high":
      if let value = try? container.decode(ProgressPayload.self, forKey: .payload) {
        payload = .progress(value)
      } else {
        payload = nil
      }
    case "progress_split":
      if let value = try? container.decode(ProgressSplitPayload.self, forKey: .payload) {
        payload = .progressSplit(value)
      } else {
        payload = nil
      }
    case "time_window":
      if let value = try? container.decode(TimeWindowPayload.self, forKey: .payload) {
        payload = .timeWindow(value)
      } else {
        payload = nil
      }
    case "storage":
      if let value = try? container.decode(StoragePayload.self, forKey: .payload) {
        payload = .storage(value)
      } else {
        payload = nil
      }
    case "sys_notify":
      if let value = try? container.decode(SysNotifyPayload.self, forKey: .payload) {
        payload = .sysNotify(value)
      } else {
        payload = .sysNotify(SysNotifyPayload())
      }
    case "input":
      if let value = try? container.decode(InputPayload.self, forKey: .payload) {
        payload = .input(value)
      } else {
        payload = nil
      }
    case "password":
      let value = (try? container.decode(PasswordPayload.self, forKey: .payload)) ?? PasswordPayload(copy: nil)
      payload = .password(value)
    case "gps_type":
      if let value = try? container.decode(GpsPayload.self, forKey: .payload) {
        payload = .gps(value)
      } else {
        payload = .gps(GpsPayload())
      }
    case "button":
      if let value = try? container.decode(ButtonPayload.self, forKey: .payload) {
        payload = .button(value)
      } else {
        payload = nil
      }
    case "readonly":
      if let value = try? container.decode(ReadonlyPayload.self, forKey: .payload) {
        payload = .readonly(value)
      } else {
        payload = nil
      }
    case "logo":
      let value = (try? container.decode(LogoPayload.self, forKey: .payload)) ?? LogoPayload()
      payload = .logo(value)
    case "order":
      payload = .order(OrderPayload())
    default:
      payload = nil
    }
  }
}

struct SettingReason: Decodable {
  let r: String?
  let e: String?
  let msg: String
  let type: String

  let appPath: String?
  let miniPath: String?
  let params: [String: String]?
}

struct SettingTemplateData: Decodable {
  var template: [TemplateItem]
  let reason: [SettingReason]?
  let error: [SettingReason]?
}
