import SwiftUI

struct VehicleEditFuelView: View {
  @ObservedObject private var appNavigation = AppNavigationModel.shared
  let imei: String
  @State private var tank: String = ""
  @State private var focusOnceToken: Int = 0
  @State private var isLoading = false

  var body: some View {
    VStack(spacing: 0) {
      // Spacer().frame(height: safeAreaTop).background(Color.white)
      NavHeader(title: "修改油箱容量")

      ScrollView {
        VStack(spacing: 16) {
          HStack(spacing: 16) {
            Text("油箱容量")
              .font(.system(size: 16, weight: .medium))
              .foregroundColor(Color(hex: "0x111111"))
              .frame(width: 70, alignment: .leading)

            TextField("请输入油箱容量", text: $tank)
              .keyboardType(.numberPad)
              .font(.system(size: 16))
              .foregroundColor(Color(hex: "0x333333"))
              .focusOneTime($focusOnceToken)

            Text("L")
              .font(.system(size: 16))
              .foregroundColor(Color(hex: "0x999999"))
          }
          .padding(.horizontal, 16)
          .frame(height: 56)
          .background(Color.white)
          .cornerRadius(8)

          Button {
            save()
          } label: {
            Text("保存")
              .font(.system(size: 16, weight: .medium))
              .padding(.horizontal, 24)
              .foregroundColor(.white)
              .frame(maxWidth: .infinity)
              .frame(height: 48)
              .background(Color(hex: "0x06BAFF"))
              .cornerRadius(8)
          }
          .disabled(isLoading || tank.isEmpty)
          .padding(.top, 24)
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
      }
      .background(Color(hex: "0xF8F8F8").ignoresSafeArea())
    }
    .ignoresSafeArea()
    .navigationBarHidden(true)
    .onTapGesture {
      UIApplication.shared.dismissKeyboard()
    }
    .onAppear {
      if let vehicle = VehiclesStore.shared.hashVehicles[imei] {
        let tankValue = vehicle.car?.tank ?? 0
        tank = tankValue > 0 ? "\(tankValue)" : ""
        if tankValue <= 0 {
          focusOnceToken &+= 1
        }
      }
    }
    .vehicleSettingsUpdatingOverlay(isLoading)
  }

  private func save() {
    // Step 1. 解析油箱容量输入
    guard let tankVal = Int(tank) else { return }
    isLoading = true

    Task {
      // Step 2. 提交油箱容量更新
      let payload = VehicleSetCarInfoPayload(imei: imei, tank: tankVal)
      // Step 3. 刷新车辆信息并返回
      let result = await VehicleAPI.shared.setCarInfo(payload: payload)
      await VehiclesStore.shared.refresh()
      await MainActor.run {
        isLoading = false
        if result != nil {
          ToastCenter.shared.show("修改成功")
          appNavigation.pop()
        }
      }
    }
  }
}
