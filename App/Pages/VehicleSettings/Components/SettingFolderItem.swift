import SwiftUI
import UIKit

struct SettingFolderItem: View {
  let item: TemplateItem
  let payload: FolderPayload
  let isEnabled: Bool
  private let appNavigation = AppNavigationModel.shared
  @ObservedObject private var store = TemplateStore.shared

  var body: some View {
    Button {
      guard isEnabled else { return }
      if let c = item.c {
        if c == "17" {
          appNavigation.push(.settingVoiceCommand)
          return
        }
        if c == "18" {
          if let imei = store.currentImei, !imei.isEmpty {
            appNavigation.push(.settingGps(imei: imei))
          } else {
            ToastCenter.shared.show("设备信息缺失")
          }
          return
        }
      }
      if let items = payload.items, !items.isEmpty {
        appNavigation.push(.settingSubPage(title: item.item ?? "设置", items: items))
      } else {
        ToastCenter.shared.show("暂无子项")
      }
    } label: {
      HStack {
        // DONE-AI: 已按 TemplateItem.icon 直接渲染资源图标
        if let icon = resolvedIconName {
          Image(icon)
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20)
            .opacity(isEnabled ? 1 : 0.45)
        }

        VStack(alignment: .leading, spacing: 6) {
          Text(item.item ?? "")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(Color(hex: isEnabled ? "0x111111" : "0xB0B0B0"))

          if let describe = item.describe, !describe.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Text(describe)
              .font(.system(size: 14))
              .foregroundColor(Color(hex: isEnabled ? "0x999999" : "0xC6C6C6"))
              .fixedSize(horizontal: false, vertical: true)
          }
        }

        Spacer()

        Image("icon_more_arrow") // Assuming this asset exists
          .resizable()
          .scaledToFit()
          .frame(width: 16, height: 16)
          .foregroundColor(Color(hex: isEnabled ? "0xCCCCCC" : "0xE0E0E0"))
      }
      .padding(.vertical, 12)
      .background(Color.white)
      .cornerRadius(8)
      .opacity(isEnabled ? 1 : 0.65)
    }
    .buttonStyle(.plain)
    .disabled(!isEnabled)
  }

  private var resolvedIconName: String? {
    guard let icon = item.icon, !icon.isEmpty else { return nil }
    if UIImage(named: icon) != nil {
      return icon
    }

    if UIImage(named: "icon_settings") != nil {
      return "icon_settings"
    }
    return nil
  }
}
