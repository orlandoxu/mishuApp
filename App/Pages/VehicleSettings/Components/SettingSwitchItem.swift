import SwiftUI

struct SettingSwitchItem: View {
  let item: TemplateItem
  let payload: SwitchPayload
  @ObservedObject private var store = TemplateStore.shared
  @State private var isUpdating = false

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 6) {
        Text(item.item ?? "")
          .font(.system(size: 16, weight: .medium))
          .foregroundColor(Color(hex: "0x111111"))

        if let describe = item.describe, !describe.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          Text(describe)
            .font(.system(size: 14))
            .foregroundColor(Color(hex: "0x999999"))
            .fixedSize(horizontal: false, vertical: true)
        }
      }

      Spacer()

      Toggle("", isOn: Binding(
        get: {
          guard let c = item.c, let setting = store.settings[c], let v = setting.v else { return false }
          return v == (payload.trueVal ?? "1")
        },
        set: { newValue in
          handleToggle(newValue)
        }
      ))
      .labelsHidden()
      .toggleStyle(SwitchToggleStyle(tint: Color(hex: "0x06BAFF")))
      .disabled(isUpdating)
    }
    .padding(.vertical, 12)
    .background(Color.white)
    .vehicleSettingsUpdatingOverlay(isUpdating)
  }

  private func handleToggle(_ isOn: Bool) {
    isUpdating = true
    let value = isOn ? (payload.trueVal ?? "1") : (payload.falseVal ?? "0")
    Task {
      let success = await store.updateSetting(item: item, value: value)
      if !success {
        ToastCenter.shared.show("设置失败，请稍后再试")
      }
      isUpdating = false
    }
  }
}
