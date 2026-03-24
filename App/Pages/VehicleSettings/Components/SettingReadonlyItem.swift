import SwiftUI

struct SettingReadonlyItem: View {
  let item: TemplateItem
  let payload: ReadonlyPayload
  @ObservedObject private var store = TemplateStore.shared

  var body: some View {
    HStack(alignment: .center, spacing: 12) {
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

      HStack(alignment: .center, spacing: 8) {
        Text(formattedValue)
          .font(.system(size: 14))
          .foregroundColor(Color(hex: payload.color ?? "0x666666")) // Use payload color or default

        if payload.copy == true {
          Button {
            UIPasteboard.general.string = formattedValue
            ToastCenter.shared.show("已复制")
          } label: {
            Image(systemName: "doc.on.doc")
              .font(.system(size: 20))
              .foregroundColor(Color(hex: "0x999999"))
              .frame(width: 20, height: 20, alignment: .center)
          }
          .buttonStyle(.plain)
        }
      }
      .frame(height: 24, alignment: .center)
    }
    // .frame(minHeight: 44, alignment: .center)
    .padding(.vertical, 12)
    .background(Color.white)
    .cornerRadius(8)
  }

  private var formattedValue: String {
    guard let c = item.c, let setting = store.settings[c], let v = setting.v else { return "" }

    if let unit = payload.unit {
      if let doubleVal = Double(v), let mul = unit.mul {
        let value = doubleVal * mul
        // Format logic: if integer, show int, else 2 decimal places?
        let formatted = String(format: "%g", value)
        return "\(formatted)\(unit.unit ?? "")"
      } else {
        return "\(v)\(unit.unit ?? "")"
      }
    }
    return v
  }
}
