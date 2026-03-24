import SwiftUI

struct SettingRadioItem: View {
  let item: TemplateItem
  let payload: RadioPayload
  @ObservedObject private var store = TemplateStore.shared
  @State private var isUpdating = false

  var body: some View {
    let c = item.c ?? ""
    let currentValue = store.settings[c]?.v
    let options = filteredOptions(payload.items ?? [], allowed: store.settings[c]?.l)
    let rows = buildRows(options)
    let optionHeight: CGFloat = 44
    let rowGap: CGFloat = 12
    let totalHeight = CGFloat(rows.count) * optionHeight + CGFloat(max(rows.count - 1, 0)) * rowGap

    VStack(alignment: .leading, spacing: 12) {
      Text(item.item ?? "")
        .font(.system(size: 18, weight: .medium))
        .foregroundColor(ThemeColor.gray900)

      if !rows.isEmpty {
        GeometryReader { geo in
          let gap: CGFloat = 12
          VStack(alignment: .leading, spacing: rowGap) {
            ForEach(0 ..< rows.count, id: \.self) { rowIndex in
              let row = rows[rowIndex]
              let unitWidth = max(0, (geo.size.width - gap * CGFloat(max(row.count - 1, 0))) / 12.0)

              HStack(alignment: .center, spacing: gap) {
                ForEach(row, id: \.k) { option in
                  let wUnits = normalizedWidthUnits(option.width)
                  optionCell(option, selectedValue: currentValue)
                    .frame(width: unitWidth * CGFloat(wUnits), height: optionHeight)
                }
              }
            }
          }
          .disabled(isUpdating)
        }
        .frame(height: totalHeight)
      }

      if let describe = item.describe, !describe.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        Text(describe)
          .font(.system(size: 14))
          .foregroundColor(ThemeColor.gray500)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .padding(.vertical, 12)
    .background(Color.white)
    .vehicleSettingsUpdatingOverlay(isUpdating)
  }

  @ViewBuilder
  private func optionCell(_ option: RadioPayload.Item, selectedValue: String?) -> some View {
    let isSelected = option.k == selectedValue

    Button {
      selectOption(option)
    } label: {
      ZStack(alignment: .bottomTrailing) {
        RoundedRectangle(cornerRadius: 8)
          .fill(isSelected ? Color(hex: "0xE8F6FF") : Color.white)
          .overlay(
            RoundedRectangle(cornerRadius: 8)
              .stroke(isSelected ? Color(hex: "0x06BAFF") : Color(hex: "0xD6DDE6"), lineWidth: 1)
          )

        Text(option.v ?? "")
          .font(.system(size: 16, weight: .medium))
          .foregroundColor(Color(hex: isSelected ? "0x06BAFF" : "0x111111"))
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

        if isSelected {
          Image("icon_selected_mark")
            .resizable()
            .scaledToFit()
            .frame(width: 16, height: 16)
        }
      }
    }
    .buttonStyle(.plain)
  }

  private func selectOption(_ option: RadioPayload.Item) {
    guard let c = item.c, let value = option.k else { return }
    if store.settings[c]?.v == value {
      return
    }

    isUpdating = true
    Task {
      let success = await store.updateSetting(item: item, value: value)
      if !success {
        ToastCenter.shared.show("设置失败，请稍后再试")
      }
      isUpdating = false
    }
  }

  private func buildRows(_ options: [RadioPayload.Item]) -> [[RadioPayload.Item]] {
    var rows: [[RadioPayload.Item]] = []
    var current: [RadioPayload.Item] = []
    var sum = 0
    for opt in options {
      let w = normalizedWidthUnits(opt.width)
      if sum + w > 12 {
        if !current.isEmpty {
          rows.append(current)
        }
        current = [opt]
        sum = w
      } else {
        current.append(opt)
        sum += w
      }
    }
    if !current.isEmpty {
      rows.append(current)
    }
    return rows
  }

  private func normalizedWidthUnits(_ raw: Int?) -> Int {
    let value = raw ?? 0
    if value <= 0 { return 12 }
    if value >= 12 { return 12 }
    return value
  }

  private func filteredOptions(_ options: [RadioPayload.Item], allowed: [String]?) -> [RadioPayload.Item] {
    guard let allowed, !allowed.isEmpty else { return options }
    let allowSet = Set(allowed)
    return options.filter { option in
      guard let key = option.k else { return false }
      return allowSet.contains(key)
    }
  }
}
