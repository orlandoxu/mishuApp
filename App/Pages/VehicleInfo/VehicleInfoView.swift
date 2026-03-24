import Kingfisher
import SwiftUI

struct VehicleInfoView: View {
  @ObservedObject private var appNavigation = AppNavigationModel.shared
  @StateObject private var vehiclesStore = VehiclesStore.shared
  let imei: String

  private var vehicle: VehicleModel? {
    vehiclesStore.vehicleDetailVehicle
  }

  private var currentImei: String {
    vehicle?.imei ?? imei
  }

  var body: some View {
    VStack(spacing: 0) {
      // Spacer().frame(height: safeAreaTop).background(Color.white)
      NavHeader(title: "车辆信息")

      if let vehicle {
        ScrollView {
          VStack(spacing: 12) {
            VStack(spacing: 16) {
              if let urlStr = vehicle.car?.carIcon, !urlStr.isEmpty, let url = URL(string: urlStr) {
                KFImage(url)
                  .resizable()
                  .scaledToFit()
                  .frame(height: 100)
              } else if let urlStr = vehicle.car?.markImgUrl, !urlStr.isEmpty, let url = URL(string: urlStr) {
                KFImage(url)
                  .resizable()
                  .scaledToFit()
                  .frame(height: 100)
              } else {
                Image(systemName: "car.fill")
                  .resizable()
                  .scaledToFit()
                  .frame(height: 80)
                  .foregroundColor(.gray.opacity(0.3))
              }
              Text((vehicle.car?.brandName ?? "") + " " + (vehicle.car?.name ?? ""))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)

            VStack(spacing: 0) {
              InfoRow(title: "爱车昵称", value: vehicle.nickname.isEmpty ? "未设置" : vehicle.nickname) {
                appNavigation.push(.vehicleEditNickname(imei: currentImei))
              }
            }
            .background(Color.white)
            .cornerRadius(12)

            VStack(spacing: 0) {
              InfoRow(title: "车牌号码", value: vehicle.car?.carLicense ?? "未设置") {
                appNavigation.push(.vehicleEditLicensePlate(imei: currentImei))
              }
              Divider().padding(.leading, 16)
              InfoRow(title: "车型", value: (vehicle.car?.brandName ?? "") + " " + (vehicle.car?.name ?? "")) {
                appNavigation.push(.carBrandSelection(source: .vehicleInfo(imei: currentImei)))
              }
              Divider().padding(.leading, 16)
              InfoRow(title: "车架号", value: vehicle.car?.vin ?? "未设置") {
                appNavigation.push(.vehicleEditVin(imei: currentImei))
              }
              Divider().padding(.leading, 16)
              InfoRow(title: "总里程", value: "\(vehicle.car?.totalMiles ?? 0)".dropTailZero + " km") {
                appNavigation.push(.vehicleEditMileage(imei: currentImei))
              }
              Divider().padding(.leading, 16)
              InfoRow(title: "油箱容量", value: "\(vehicle.car?.tank ?? 0)".dropTailZero + " L") {
                appNavigation.push(.vehicleEditFuel(imei: currentImei))
              }
            }
            .background(Color.white)
            .cornerRadius(12)
          }
          .padding(16)
        }
        .background(Color(hex: "0xF5F6F7"))
      } else {
        Spacer()
        Text("车辆信息不存在")
          .foregroundColor(.gray)
        Spacer()
      }
    }
    .ignoresSafeArea()
    .navigationBarHidden(true)
    .taskOnce {
      vehiclesStore.setVehicleDetailImei(imei)
    }
  }
}

struct InfoRow: View {
  let title: String
  let value: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack {
        Text(title)
          .font(.system(size: 16))
          .foregroundColor(Color(hex: "0x333333"))
        Spacer()
        Text(value)
          .font(.system(size: 14))
          .foregroundColor(Color(hex: "0x999999"))
        Image(systemName: "chevron.right")
          .font(.system(size: 14))
          .foregroundColor(Color(hex: "0xCCCCCC"))
      }
      .padding(16)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}
