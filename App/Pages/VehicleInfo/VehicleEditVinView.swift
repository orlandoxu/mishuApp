import SwiftUI

struct VehicleEditVinView: View {
  @ObservedObject private var appNavigation = AppNavigationModel.shared
  let imei: String
  @State private var vinText: String = ""
  @State private var isFocused: Bool = false
  @State private var isLoading = false
  @State private var vinCursorIndex: Int = 0

  var body: some View {
    VStack(spacing: 0) {
      // Spacer().frame(height: safeAreaTop).background(Color.white)
      NavHeader(title: "修改车架号")

      ScrollView {
        VStack(spacing: 32) {
          Text("请输入车辆VIN码（车架号）")
            .font(.system(size: 16, weight: .regular))
            .foregroundColor(Color(hex: "0x333333"))
            .padding(.top, 40)

          VinInputView(
            text: $vinText,
            cursorIndex: $vinCursorIndex,
            isFocused: isFocused,
            onTap: {
              withAnimation {
                isFocused = true
              }
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
        .contentShape(Rectangle())
        .onTapGesture {
          withAnimation {
            isFocused = false
          }
        }
      }

      // Keyboard
      if isFocused {
        VinKeyboard(
          onSelect: { char in
            insertVinCharacter(char)
          },
          onDelete: {
            deleteVinCharacter()
          }
        )
        .background(Color.white)
        .transition(.move(edge: .bottom))
      }
    }
    .ignoresSafeArea()
    .navigationBarHidden(true)
    .onAppear {
      loadInitialData()
    }
    .onChange(of: vinText) { newValue in
      if newValue.count > 17 {
        vinText = String(newValue.prefix(17))
      }
      vinCursorIndex = min(vinCursorIndex, vinText.count)
    }
    .vehicleSettingsUpdatingOverlay(isLoading)
  }

  private func loadInitialData() {
    let initialVin: String
    if let vehicle = VehiclesStore.shared.hashVehicles[imei] {
      initialVin = vehicle.car?.vin.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    } else {
      initialVin = ""
    }
    vinText = initialVin
    vinCursorIndex = min(vinText.count, 16)
    isFocused = initialVin.isEmpty
  }

  private var canSubmit: Bool {
    vinText.count == 17
  }

  private func save() {
    // Step 1. 校验 VIN 输入
    guard canSubmit else { return }
    isLoading = true

    Task {
      // Step 2. 提交 VIN 更新
      let payload = VehicleSetCarInfoPayload(imei: imei, vin: vinText)
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

  private func insertVinCharacter(_ char: String) {
    var chars = Array(vinText)
    let index = min(vinCursorIndex, chars.count)
    if index < chars.count {
      chars[index] = Character(char)
    } else if chars.count < 17 {
      chars.append(Character(char))
    }
    vinText = String(chars)
    if vinCursorIndex < 16 {
      vinCursorIndex = min(index + 1, 16)
    }
  }

  private func deleteVinCharacter() {
    guard vinCursorIndex > 0 else { return }
    var chars = Array(vinText)
    let deleteIndex = min(vinCursorIndex - 1, chars.count - 1)
    chars.remove(at: deleteIndex)
    vinText = String(chars)
    vinCursorIndex = max(0, deleteIndex)
  }
}
