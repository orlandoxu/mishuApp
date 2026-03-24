import SwiftUI

struct SettingLogoItem: View {
  let item: TemplateItem
  let payload: LogoPayload
  @ObservedObject private var store = TemplateStore.shared

  var body: some View {
    VStack(spacing: 24) {
      Image("img_device_demo")

      Text("IMEI: \(imeiText)")
        .font(.system(size: 20, weight: .regular))
        .foregroundColor(Color(hex: "0x333333"))
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 30)
    .cornerRadius(8)
  }

  private var imeiText: String {
    let value = store.currentImei?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return value.isEmpty ? "-" : value
  }
}
