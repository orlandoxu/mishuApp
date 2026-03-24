import Foundation
import SwiftUI

@MainActor
final class TemplateStore: ObservableObject {
  static let shared = TemplateStore()

  @Published var templates: [TemplateItem] = [] // 这是从服务器拉取的模板（原始的）
  @Published var settings: [String: SettingBackendData] = [:]
  @Published var reasons: [SettingReason] = []
  @Published var errors: [SettingReason] = []
  @Published var isLoading: Bool = false
  @Published var errorMessage: String? = nil
  var currentImei: String?

  func refresh(imei: String) async {
    currentImei = imei
    if isLoading { return }
    isLoading = true
    errorMessage = nil
    // Step 1. 拉取模板
    if let data = await SettingAPI.shared.getTemplateData(imei: imei) {
      templates = data.template
      reasons = data.reason ?? []
      errors = data.error ?? []
    } else {
      templates = []
      reasons = []
      errors = []
      errorMessage = "获取配置失败"
    }

    // Step 2. 并行拉取配置项
    async let backendSettings = SettingAPI.shared.queryBackendSetting(imei: imei)
    async let deviceSettings = SettingAPI.shared.queryDeviceSetting(imei: imei)

    let backend = await backendSettings
    let device = await deviceSettings

    // Step 3. 合并配置项
    var newSettings: [String: SettingBackendData] = [:]
    backend?.forEach { item in
      if let c = item.c { newSettings[c] = item }
    }
    device?.forEach { item in
      if let c = item.c { newSettings[c] = item }
    }
    settings = newSettings
    isLoading = false
  }

  func updateSetting(item: TemplateItem, value: String) async -> Bool {
    guard let c = item.c else { return false }
    return await updateSetting(c: c, cmd: item.cmd, source: item.source, value: value)
  }

  func updateSetting(c: String, cmd: String?, source: String?, value: String) async -> Bool {
    guard let imei = currentImei else { return false }

    // Step 1. 调用接口
    if source == "backend" {
      guard let cmd else { return false }
      let patch = await SettingAPI.shared.setBackendSettings(imei: imei, action: cmd, params: value)
      guard let patch else { return false }
      withAnimation { mergeSettingsPatch(patch) }
    } else {
      let action = cmd ?? c
      let patch = await SettingAPI.shared.setDeviceSettings(imei: imei, action: action, params: value)
      guard let patch else { return false }
      withAnimation { mergeSettingsPatch(patch) }
    }

    return true
  }

  func updateSetting(c: String, source: String?, value: String) async -> Bool {
    await updateSetting(c: c, cmd: nil, source: source, value: value)
  }

  private func mergeSettingsPatch(_ patch: [SettingBackendData]) {
    var next = settings

    if patch.isEmpty { return }

    // Step 1. 逐条把服务端返回的“变化项”合并进本地 settings
    for item in patch {
      guard let c = item.c else { continue }
      if let existing = next[c] {
        next[c] = existing.merged(with: item)
      } else {
        next[c] = item
      }
    }

    // Step 2. 回写 settings（触发 UI 刷新）
    settings = next
  }
}
