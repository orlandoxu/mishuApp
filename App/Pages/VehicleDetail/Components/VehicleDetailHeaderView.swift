import SwiftUI
import UIKit

struct VehicleDetailHeaderView: View {
  let vehicle: VehicleModel
  @Environment(\.presentationMode) var presentationMode

  var body: some View {
    VStack(spacing: 0) {
      // Custom Navigation Bar
      HStack(alignment: .top) {
        Button {
          presentationMode.wrappedValue.dismiss()
        } label: {
          Image(systemName: "chevron.left")
            .font(.system(size: 20, weight: .medium))
            .foregroundColor(.black)
        }
        .padding(.top, 4)

        VStack(alignment: .leading, spacing: 4) {
          Text(headerTitle)
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(.black)

          if let vin = vehicle.car?.vin, !vin.isEmpty {
            Button {
              copyVin(vin)
            } label: {
              HStack(spacing: 4) {
                Text(vin)
                  .font(.system(size: 12))
                  .foregroundColor(.gray)

                Image(systemName: "doc.on.doc")
                  .font(.system(size: 10))
                  .foregroundColor(.gray)
              }
              .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.leading, 8)

        Spacer()

        Text((vehicle.car?.brandName ?? "") + (vehicle.car?.name ?? ""))
          .font(.system(size: 14))
          .foregroundColor(.gray)
          .padding(.top, 8)
      }
      .padding(.horizontal, 16)
      .padding(.bottom, 8)
    }
  }

  private func copyVin(_ vin: String) {
    let value = vin.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !value.isEmpty else {
      ToastCenter.shared.show("暂无可复制内容")
      return
    }
    UIPasteboard.general.string = value
    ToastCenter.shared.show("已复制")
  }

  private var headerTitle: String {
    let nickname = vehicle.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
    if !nickname.isEmpty { return nickname }
    let license = vehicle.car?.carLicense.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    if !license.isEmpty { return license }
    return "未设置车牌号"
  }
}
