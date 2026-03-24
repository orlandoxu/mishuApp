import SwiftUI

struct Header4LiveView: View {
  @EnvironmentObject private var viewModel: VehicleLiveViewModel

  var body: some View {
    VStack(spacing: 0) {
      // Spacer().frame(height: safeAreaTop).background(Color.white)
      NavHeader(title: liveTitle, onBack: {
        viewModel.tapBack()
      }) {
        HStack(spacing: 12) {
          if viewModel.isLiveWifiMode {
            Text("当前是WIFI模式")
              .font(.system(size: 16, weight: .semibold))
              .foregroundColor(Color(hex: "0x9CA3AF"))
          }
        }
      }
    }
  }

  private var liveTitle: String {
    if let vehicle = viewModel.currLiveVehicle {
      if let license = vehicle.car?.carLicense, !license.isEmpty {
        return license
      }
      if !vehicle.nickname.isEmpty {
        return vehicle.nickname
      }
      if !vehicle.imei.isEmpty {
        return vehicle.imei
      }
    }
    let imeiText = viewModel.liveImei ?? ""
    return imeiText.isEmpty ? "未设置车牌" : imeiText
  }
}
