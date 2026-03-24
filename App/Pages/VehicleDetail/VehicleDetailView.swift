import SwiftUI

struct VehicleDetailView: View {
  let imei: String?

  @StateObject private var vehiclesStore: VehiclesStore = .shared

  var vehicle: VehicleModel? {
    vehiclesStore.vehicleDetailVehicle
  }

  var loadFinished: Bool {
    vehicle?.tripStats != nil
  }

  var body: some View {
    let targetImei = imei ?? vehiclesStore.vehicleDetailImei

    Group {
      if loadFinished {
        VehicleDetailContentView(vehicle: vehicle!)
      } else if targetImei == nil || targetImei?.isEmpty == true {
        Text("车辆信息缺失").frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        ProgressView()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .taskOnce {
      guard let targetImei, !targetImei.isEmpty else { return }
      vehiclesStore.setVehicleDetailImei(targetImei)

      await vehiclesStore.loadVehicleDetailAll()
    }
  }
}

private struct VehicleDetailContentView: View {
  let vehicle: VehicleModel
  @StateObject private var vehiclesStore: VehiclesStore = .shared

  var body: some View {
    VStack(spacing: 0) {
      Spacer().frame(height: safeAreaTop + 10)
      VehicleDetailHeaderView(vehicle: vehicle)

      ScrollView {
        VStack(spacing: 0) {
          VehicleDetailStatusView(vehicle: vehicle)

          VehicleDashboardView()
          // .padding(.top, 10)

          TripReportSummaryView()
            .padding(.top, 20)

          TripListView()
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
      }
    }
    .background(Color("EFF2F8"))
    .ignoresSafeArea()
    .navigationBarHidden(true)
  }
}
