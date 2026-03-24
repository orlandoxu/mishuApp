import SwiftUI

struct VehicleEditLicensePlateView: View {
  @ObservedObject private var appNavigation = AppNavigationModel.shared
  let imei: String
  @State private var chars: [String] = Array(repeating: "", count: 8)
  @State private var currentIndex: Int = 0
  @State private var isLoading = false

  var body: some View {
    VStack(spacing: 0) {
      // Spacer().frame(height: safeAreaTop).background(Color.white)
      NavHeader(title: "修改车牌号码")

      ScrollView {
        VStack(spacing: 32) {
          Text("请输入车牌号码")
            .font(.system(size: 16, weight: .regular))
            .foregroundColor(Color(hex: "0x333333"))
            .padding(.top, 40)

          LicensePlateInputView(
            chars: chars,
            currentIndex: currentIndex,
            onTapIndex: { index in
              currentIndex = index
            }
          )
          .frame(maxWidth: .infinity)

          Button {
            save()
          } label: {
            Text("保存")
              .font(.system(size: 16, weight: .semibold))
              .foregroundColor(.white)
              .frame(maxWidth: .infinity)
              .frame(height: 50)
              .background(canSubmit ? Color(hex: "0x06BAFF") : Color(hex: "0x06BAFF").opacity(0.6))
              .cornerRadius(8)
          }
          .buttonStyle(.plain)
          .disabled(!canSubmit || isLoading)
          .padding(.top, 20)

          Spacer(minLength: 50)
        }
        .padding(.horizontal, 24)
      }

      // Keyboard
      VStack(spacing: 0) {
        if currentIndex == 0 {
          ProvinceKeyboard(
            onSelect: { province in
              handleInput(province)
            }
          )
        } else {
          AlphanumericKeyboard(
            isFirstLetter: currentIndex == 1,
            onSelect: { char in
              handleInput(char)
            },
            onDelete: {
              handleDelete()
            },
            onClear: {
              handleClear()
            }
          )
        }
      }
      .padding(.bottom, safeAreaBottom)
      .background(Color.white)
    }
    .ignoresSafeArea()
    .navigationBarHidden(true)
    .onAppear {
      loadInitialData()
    }
    .vehicleSettingsUpdatingOverlay(isLoading)
  }

  private func loadInitialData() {
    guard let vehicle = VehiclesStore.shared.hashVehicles[imei],
          let license = vehicle.car?.carLicense, !license.isEmpty else { return }

    // Parse license
    var tempChars = Array(repeating: "", count: 8)
    let licenseChars = Array(license)
    for (i, char) in licenseChars.enumerated() {
      if i < 8 {
        tempChars[i] = String(char)
      }
    }
    chars = tempChars
    currentIndex = min(licenseChars.count, 7)
  }

  private func handleInput(_ text: String) {
    if currentIndex >= 8 { return }
    chars[currentIndex] = text
    if currentIndex < 7 {
      currentIndex += 1
    }
  }

  private func handleDelete() {
    if !chars[currentIndex].isEmpty {
      chars[currentIndex] = ""
    } else {
      if currentIndex > 0 {
        currentIndex -= 1
        chars[currentIndex] = ""
      }
    }
  }

  private func handleClear() {
    chars = Array(repeating: "", count: 8)
    currentIndex = 0
  }

  private var canSubmit: Bool {
    let count = chars.filter { !$0.isEmpty }.count
    return count >= 7
  }

  private func save() {
    // Step 1. 组装车牌号
    let plateNo = chars.joined()
    guard !plateNo.isEmpty else { return }
    isLoading = true

    Task {
      // Step 2. 提交车牌号更新
      let payload = VehicleSetCarInfoPayload(imei: imei, carLicense: plateNo)
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

  private var safeAreaBottom: CGFloat {
    UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
  }
}
