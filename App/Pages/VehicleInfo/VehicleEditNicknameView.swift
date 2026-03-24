import SwiftUI

struct VehicleEditNicknameView: View {
  @ObservedObject private var appNavigation = AppNavigationModel.shared
  let imei: String
  @State private var nickname: String = ""
  @State private var isLoading = false

  private var disabled: Bool {
    isLoading || nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  var body: some View {
    VStack(spacing: 0) {
      // Spacer().frame(height: safeAreaTop).background(Color.white)
      NavHeader(title: "修改爱车昵称")

      ScrollView {
        VStack(spacing: 16) {
          HStack(spacing: 16) {
            Text("昵称")
              .font(.system(size: 16, weight: .medium))
              .foregroundColor(Color(hex: "0x111111"))
              .frame(width: 40, alignment: .leading)

            TextField("请输入昵称", text: $nickname)
              .font(.system(size: 16))
              .foregroundColor(Color(hex: "0x333333"))
          }
          .padding(.horizontal, 16)
          .frame(height: 56)
          .background(Color.white)
          .cornerRadius(8)

          Button {
            save()
          } label: {
            Text("确定")
              .font(.system(size: 16, weight: .medium))
              .padding(.horizontal, 24)
              .foregroundColor(.white)
              .frame(maxWidth: .infinity)
              .frame(height: 48)
              .background(disabled ? Color(hex: "0x06BAFF").opacity(0.4) : Color(hex: "0x06BAFF"))
              .cornerRadius(8)
          }
          .disabled(disabled)
          .padding(.top, 24)
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
      }
      .background(Color(hex: "0xF8F8F8").ignoresSafeArea())
    }
    .ignoresSafeArea()
    .navigationBarHidden(true)
    .onAppear {
      if let vehicle = VehiclesStore.shared.hashVehicles[imei] {
        nickname = vehicle.nickname
      }
    }
    .vehicleSettingsUpdatingOverlay(isLoading)
  }

  private func save() {
    // Step 1. 校验昵称输入
    let next = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !next.isEmpty else { return }
    isLoading = true

    Task {
      // Step 2. 提交昵称更新
      let payload = VehicleSetCarInfoPayload(imei: imei, nickname: next)
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
