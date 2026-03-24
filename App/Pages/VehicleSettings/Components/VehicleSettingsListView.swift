import SwiftUI

struct VehicleSettingsListView: View {
  let items: [TemplateItem]
  @ObservedObject private var store = TemplateStore.shared
  // 版本裁剪：以下 folder 需求本期来不及开发，先在渲染层直接隐藏。
  private let hiddenFolderIds: Set<String> = ["20", "4", "6", "12", "13", "14"]

  var body: some View {
    LazyVStack(spacing: 12) {
      ForEach(items, id: \.c) { item in
        renderItem(item)
      }
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 12)
  }

  private func renderItem(_ item: TemplateItem) -> AnyView {
    switch item.payload {
    case let .folder(payload):
      if !shouldRender(item) {
        return AnyView(EmptyView())
      }
      let filteredItems = (payload.items ?? []).filter(shouldRender)
      let filteredPayload = FolderPayload(items: filteredItems)
      let isEnabled = item.c == "17" || !filteredItems.isEmpty
      return AnyView(SettingFolderItem(item: item, payload: filteredPayload, isEnabled: isEnabled))
    case let .group(payload):
      if !shouldRender(item) {
        return AnyView(EmptyView())
      }
      let filteredItems = (payload.items ?? []).filter(shouldRender)
      if filteredItems.isEmpty {
        return AnyView(EmptyView())
      }
      return AnyView(
        VStack {
          // 如果有名字，就要显示title
          if let title = item.item, !title.isEmpty {
            Text(title)
              .font(.headline)
              .foregroundColor(.primary)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.top, 12)
              .padding(.horizontal, 16)
          }

          VStack(spacing: 4) {
            ForEach(filteredItems, id: \.c) { child in
              renderItem(child)
            }
          }
          .padding(.vertical, 10)
          .padding(.horizontal, 20)
          .background(Color.white)
          .cornerRadius(12)
        }
      )
    case let .switchValue(payload):
      if !shouldRender(item) {
        return AnyView(EmptyView())
      }
      return renderWithAvailability(SettingSwitchItem(item: item, payload: payload), item: item)
    case let .radio(payload):
      if !shouldRender(item) {
        return AnyView(EmptyView())
      }
      return renderWithAvailability(SettingRadioItem(item: item, payload: payload), item: item)
    case let .button(payload):
      if !shouldRender(item) {
        return AnyView(EmptyView())
      }
      return renderWithAvailability(SettingButtonItem(item: item, payload: payload), item: item)
    case let .readonly(payload):
      if !shouldRender(item) {
        return AnyView(EmptyView())
      }
      return renderWithAvailability(SettingReadonlyItem(item: item, payload: payload), item: item)
    case let .progress(payload):
      if !shouldRender(item) {
        return AnyView(EmptyView())
      }
      return renderWithAvailability(SettingProgressItem(item: item, payload: payload), item: item)
    case let .input(payload):
      if !shouldRender(item) {
        return AnyView(EmptyView())
      }
      return renderWithAvailability(SettingInputItem(item: item, payload: payload), item: item)
    case let .password(payload):
      if !shouldRender(item) {
        return AnyView(EmptyView())
      }
      return renderWithAvailability(SettingPasswordItem(item: item, payload: payload), item: item)
    case let .gps(payload):
      if !shouldRender(item) {
        return AnyView(EmptyView())
      }
      return renderWithAvailability(SettingGpsItem(item: item, payload: payload), item: item)
    case let .timeWindow(payload):
      if !shouldRender(item) {
        return AnyView(EmptyView())
      }
      return renderWithAvailability(SettingTimeWindowItem(item: item, payload: payload), item: item)
    case let .storage(payload):
      if !shouldRender(item) {
        return AnyView(EmptyView())
      }
      let filteredItems = (payload.items ?? []).filter(shouldRender)
      if filteredItems.isEmpty {
        return AnyView(EmptyView())
      }
      let filteredPayload = StoragePayload(items: filteredItems)
      return AnyView(SettingStorageItem(item: item, payload: filteredPayload))
    case let .sysNotify(payload):
      _ = payload
      if !shouldRender(item) {
        return AnyView(EmptyView())
      }
      return AnyView(SettingSysNotifyItem(item: item))
    case let .logo(payload):
      if !shouldRender(item) {
        return AnyView(EmptyView())
      }
      return AnyView(SettingLogoItem(item: item, payload: payload))
    default:
      if item.type != "space" {
        return AnyView(
          Text("Unsupported type: \(item.type)")
            .font(.caption)
            .foregroundColor(.red)
            .frame(maxWidth: .infinity, alignment: .leading)
        )
      }
      return AnyView(EmptyView())
    }
  }

  private func shouldRender(_ item: TemplateItem) -> Bool {
    if item.c == "17" { // 目前先写死，语音手册，目前没有纳入到设置项里面来
      return true
    }

    switch item.payload {
    case let .folder(payload):
      if let folderId = item.c, hiddenFolderIds.contains(folderId) {
        return false
      }
      // 需求：folder 始终显示，不可用时灰显禁用
      _ = payload
      return true
    case let .group(payload):
      return shouldRenderContainer(item: item, children: payload.items ?? [])
    case let .storage(payload):
      return shouldRenderContainer(item: item, children: payload.items ?? [])
    default:
      return shouldRenderLeaf(item)
    }
  }

  private func shouldRenderContainer(item: TemplateItem, children: [TemplateItem]) -> Bool {
    if item.show == 1 || item.show == 2 {
      return true
    }
    return children.contains { shouldRender($0) }
  }

  private func shouldRenderLeaf(_ item: TemplateItem) -> Bool {
    if item.show == 2 {
      return true
    }

    if item.type == "sys_notify" {
      return true
    }

    if item.type == "logo" {
      return true
    }

    if item.show == 1 {
      return true
    }

    return isSettingSupported(item)
  }

  private func renderWithAvailability<V: View>(_ view: V, item: TemplateItem) -> AnyView {
    let disabled = shouldRenderAsDisabled(item)
    return AnyView(
      view
        .opacity(disabled ? 0.45 : 1)
        .allowsHitTesting(!disabled)
    )
  }

  private func shouldRenderAsDisabled(_ item: TemplateItem) -> Bool {
    guard item.show == 1 else {
      return false
    }
    return !isSettingSupported(item)
  }

  private func isSettingSupported(_ item: TemplateItem) -> Bool {
    if item.type == "logo" || item.type == "sys_notify" {
      return true
    }

    guard let c = item.c, let setting = store.settings[c] else {
      return false
    }

    guard let support = setting.s else {
      return true
    }

    if support != "1" {
      return false
    }

    return true
  }
}

private struct SettingStorageItem: View {
  let item: TemplateItem
  let payload: StoragePayload
  @ObservedObject private var store = TemplateStore.shared

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(titleText)
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(Color(hex: "0x111111"))

      VStack(alignment: .leading, spacing: 12) {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
          Text(totalValueText)
            .font(.system(size: 28, weight: .bold))
            .foregroundColor(Color(hex: "0x111111"))

          Text(totalUnitText)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(Color(hex: "0x111111"))
            .offset(y: -2)

          Spacer()
        }

        GeometryReader { proxy in
          ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 4)
              .fill(Color(hex: "0xEFEFEF"))
              .frame(height: 8)

            RoundedRectangle(cornerRadius: 4)
              .fill(Color(hex: "0x06BAFF"))
              .frame(width: max(0, min(proxy.size.width, proxy.size.width * progress)), height: 8)
          }
        }
        .frame(height: 8)

        HStack {
          HStack(spacing: 8) {
            Circle()
              .fill(Color(hex: "0x06BAFF"))
              .frame(width: 8, height: 8)
            Text("已用\(usedText)")
              .font(.system(size: 14))
              .foregroundColor(Color(hex: "0x666666"))
          }

          Spacer()

          HStack(spacing: 8) {
            Circle()
              .fill(Color(hex: "0xE5E5E5"))
              .frame(width: 8, height: 8)
            Text("剩余\(remainingText)")
              .font(.system(size: 14))
              .foregroundColor(Color(hex: "0x666666"))
          }
        }
      }
      .padding(16)
      .background(Color.white)
      .cornerRadius(12)
      .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }
  }

  private var titleText: String {
    if let itemText = item.item, !itemText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      return itemText
    }
    return "TF卡状态"
  }

  private var totalMB: Double {
    valueFor("131")
  }

  private var remainingMB: Double {
    valueFor("132")
  }

  private var usedMB: Double {
    max(0, totalMB - remainingMB)
  }

  private var progress: CGFloat {
    if totalMB <= 0 { return 0 }
    return CGFloat(usedMB / totalMB)
  }

  private var totalValueText: String {
    formatCapacity(totalMB).value
  }

  private var totalUnitText: String {
    let unit = formatCapacity(totalMB).unit
    if unit == "G" { return "GB" }
    return unit
  }

  private var usedText: String {
    let formatted = formatCapacity(usedMB)
    return "\(formatted.value)\(formatted.unit)"
  }

  private var remainingText: String {
    let formatted = formatCapacity(remainingMB)
    return "\(formatted.value)\(formatted.unit)"
  }

  private func valueFor(_ code: String) -> Double {
    guard let items = payload.items else { return 0 }
    guard let target = items.first(where: { $0.c == code }), let c = target.c else { return 0 }
    guard let raw = store.settings[c]?.v?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return 0 }
    return Double(raw) ?? 0
  }

  private func formatCapacity(_ valueMB: Double) -> (value: String, unit: String) {
    if valueMB >= 1024 {
      let gb = valueMB / 1024
      return (String(format: "%.1f", gb), "G")
    }
    return (String(format: "%.0f", valueMB), "MB")
  }
}
