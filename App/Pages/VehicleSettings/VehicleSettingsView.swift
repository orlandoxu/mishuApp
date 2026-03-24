import SwiftUI
import UIKit

struct VehicleSettingsView: View {
  let imei: String
  @StateObject private var store = TemplateStore.shared
  @StateObject private var vehiclesStore = VehiclesStore.shared

  var body: some View {
    VStack(spacing: 0) {
      // Spacer().frame(height: safeAreaTop).background(Color.white)
      NavHeader(title: "设置")

      if store.isLoading {
        Spacer()
        ProgressView()
        Spacer()
      } else if let error = store.errorMessage {
        Spacer()
        Text(error).foregroundColor(.red)
        Button("重试") {
          Task {
            await store.refresh(imei: imei)
          }
        }
        Spacer()
      } else {
        ScrollView {
          VStack(spacing: 12) {
            deviceInfoCard
            VehicleSettingsListView(items: store.templates)
              .environmentObject(store)

            Spacer().frame(height: 200)
          }
          .padding(.top, 12)
        }
        .background(Color(hex: "0xF5F6F7"))
      }
    }
    .ignoresSafeArea()
    .navigationBarHidden(true)
    .taskOnce {
      await store.refresh(imei: imei)
    }
  }

  private var deviceInfoCard: some View {
    let vehicle = vehiclesStore.hashVehicles[imei]
    let imeiText = vehicle?.imei ?? imei
    let snText = vehicle?.sn ?? ""

    return VStack(spacing: 12) {
      deviceInfoRow(title: "IMEI：", value: imeiText)
      deviceInfoRow(title: "SN：", value: snText)
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 16)
    .cornerRadius(8)
    .padding(.horizontal, 12)
  }

  private func deviceInfoRow(title: String, value: String) -> some View {
    HStack(spacing: 12) {
      Text(title)
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(Color(hex: "0x111111"))
        .frame(width: 52, alignment: .leading)

      Text(value.isEmpty ? "-" : value)
        .font(.system(size: 16))
        .foregroundColor(Color(hex: "0x333333"))
        .lineLimit(1)

      Button {
        copyText(value)
      } label: {
        Image(systemName: "doc.on.doc")
          .foregroundColor(Color(hex: "0x999999"))
      }
      .padding(.trailing, 8)
      .buttonStyle(.plain)
      .disabled(value.isEmpty)

      Spacer()
    }
  }

  private func copyText(_ value: String) {
    guard !value.isEmpty else {
      ToastCenter.shared.show("暂无可复制内容")
      return
    }
    UIPasteboard.general.string = value
    ToastCenter.shared.show("已复制")
  }
}
