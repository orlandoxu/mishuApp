import SwiftUI

struct VehicleEditMileageView: View {
  @ObservedObject private var appNavigation = AppNavigationModel.shared
  let imei: String
  @State private var mileage: String = ""
  @State private var focusOnceToken: Int = 0
  @State private var isLoading = false

  var body: some View {
    VStack(spacing: 0) {
      NavHeader(title: "修改总里程")

      ScrollView {
        VStack(spacing: 16) {
          HStack(spacing: 16) {
            Text("总里程")
              .font(.system(size: 16, weight: .medium))
              .foregroundColor(Color(hex: "0x111111"))
              .frame(width: 60, alignment: .leading)

            TextField("请输入总里程", text: $mileage)
              .keyboardType(.numberPad)
              .font(.system(size: 16))
              .foregroundColor(Color(hex: "0x333333"))
              .focusOneTime($focusOnceToken)

            Text("km")
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
          .disabled(isLoading || mileage.isEmpty)
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
        let initialText = initialMileageText(from: vehicle.car?.totalMiles)
        mileage = initialText
        if initialText.isEmpty {
          focusOnceToken &+= 1
        }
      }
    }
    .onChange(of: mileage) { newValue in
      let digitsOnly = String(newValue.filter { $0.isNumber })
      if digitsOnly != newValue {
        mileage = digitsOnly
      }
    }
    // .vehicleSettingsUpdatingOverlay(isLoading)
  }

  private func save() {
    // Step 1. 解析总里程输入
    guard let miles = Int(mileage) else { return }
    isLoading = true

    Task {
      // Step 2. 提交总里程更新
      let payload = VehicleSetCarInfoPayload(imei: imei, totalMiles: miles)
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

  private func initialMileageText(from totalMiles: Double?) -> String {
    guard let totalMiles, totalMiles > 0 else { return "" }
    return String(Int(totalMiles))
  }
}
