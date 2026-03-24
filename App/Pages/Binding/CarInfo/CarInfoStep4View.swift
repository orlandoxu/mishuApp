import SwiftUI

struct CarInfoStep4View: View {
  @ObservedObject private var appNavigation = AppNavigationModel.shared
  @StateObject private var bindingStore: BindingStore = .shared

  var body: some View {
    ZStack {
      Color.white.ignoresSafeArea()

      VStack(spacing: 0) {
        // Navigation Bar
        HStack(spacing: 0) {
          Button {
            appNavigation.pop()
          } label: {
            ZStack {
              Circle()
                .fill(Color.black.opacity(0.001))
                .frame(width: 44, height: 44)
              Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color(hex: "0x111111"))
            }
          }
          .buttonStyle(.plain)

          Text("车辆信息")
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(Color(hex: "0x111111"))
            .padding(.leading, 4)

          Spacer()

          Text("\(bindingStore.currentStep)/\(bindingStore.totalStepCount)")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(Color(hex: "0x999999"))
        }
        .padding(.top, safeAreaTop)
        .padding(.horizontal, 16)
        .frame(height: 56 + safeAreaTop)

        ScrollView {
          VStack(alignment: .leading, spacing: 24) {
            // Mileage
            VStack(alignment: .leading, spacing: 10) {
              Text("*请输入您的表显里程")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "0x111111"))
                .padding(.top, 20)

              HStack {
                TextField("请输入", text: Binding(
                  get: { bindingStore.totalMiles },
                  set: { bindingStore.totalMiles = $0 }
                ))
                .keyboardType(.decimalPad)
                .font(.system(size: 16))

                Text("/Km")
                  .font(.system(size: 16))
                  .foregroundColor(Color(hex: "0x999999"))
              }
              .padding(.horizontal, 16)
              .frame(height: 52)
              .background(
                RoundedRectangle(cornerRadius: 8)
                  .stroke(Color(hex: "0xE5E5E5"), lineWidth: 1)
              )
            }

            // Power Type
            VStack(alignment: .leading, spacing: 10) {
              Text("*车辆类型")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "0x111111"))

              HStack(spacing: 12) {
                typeButton(title: "燃油车", value: 2)
                typeButton(title: "混动", value: 3)
                typeButton(title: "纯电", value: 1)
              }
            }

            // Auto Start
            VStack(alignment: .leading, spacing: 10) {
              Text("*您的车辆是否支持自动启停?")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "0x111111"))

              HStack(spacing: 12) {
                startStopButton(title: "YES", value: 1)
                startStopButton(title: "NO", value: 0)
              }
            }

            // Submit Button
            Button {
              submitBinding()
            } label: {
              ZStack {
                RoundedRectangle(cornerRadius: 8)
                  .fill(canSubmit ? Color(hex: "0xBDEFFF") : Color(hex: "0xBDEFFF").opacity(0.6))

                if bindingStore.isChecking {
                  ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                  Text("完成绑定")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                }
              }
              .frame(height: 50)
            }
            .buttonStyle(.plain)
            .disabled(!canSubmit || bindingStore.isChecking)
            .padding(.top, 20)

            Spacer(minLength: 0)
          }
          .padding(.horizontal, 24)
        }
      }
    }
    .navigationBarHidden(true)
    .navigationBarBackButtonHidden(true)
    .onTapGesture {
      UIApplication.shared.dismissKeyboard()
    }
  }

  private func typeButton(title: String, value: Int) -> some View {
    Button {
      bindingStore.powerType = value
    } label: {
      ZStack {
        RoundedRectangle(cornerRadius: 8)
          .stroke(bindingStore.powerType == value ? Color(hex: "0x06BAFF") : Color(hex: "0xE5E5E5"), lineWidth: 1)
          .background(bindingStore.powerType == value ? Color(hex: "0x06BAFF").opacity(0.05) : Color.white)

        HStack {
          Text(title)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(bindingStore.powerType == value ? Color(hex: "0x06BAFF") : Color(hex: "0x666666"))

          if bindingStore.powerType == value {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
              .foregroundColor(Color(hex: "0x06BAFF"))
              .font(.system(size: 12))
          }
        }
        .padding(.horizontal, 12)
      }
      .frame(height: 44)
    }
    .buttonStyle(.plain)
  }

  private func startStopButton(title: String, value: Int) -> some View {
    Button {
      bindingStore.engineAutoStart = value
    } label: {
      ZStack {
        RoundedRectangle(cornerRadius: 8)
          .stroke(bindingStore.engineAutoStart == value ? Color(hex: "0x06BAFF") : Color(hex: "0xE5E5E5"), lineWidth: 1)
          .background(bindingStore.engineAutoStart == value ? Color(hex: "0x06BAFF").opacity(0.05) : Color.white)

        HStack {
          Text(title)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(bindingStore.engineAutoStart == value ? Color(hex: "0x06BAFF") : Color(hex: "0x666666"))

          if bindingStore.engineAutoStart == value {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
              .foregroundColor(Color(hex: "0x06BAFF"))
              .font(.system(size: 12))
          }
        }
        .padding(.horizontal, 12)
      }
      .frame(height: 44)
    }
    .buttonStyle(.plain)
  }

  private var canSubmit: Bool {
    !bindingStore.totalMiles.isEmpty
  }

  private func submitBinding() {
    Task {
      do {
        try await bindingStore.submitBinding()
        await MainActor.run {
          ToastCenter.shared.show("绑定成功")
          appNavigation.root = .mainTab(.recorder)
        }
      } catch {
        await MainActor.run {
          ToastCenter.shared.show("绑定失败：\(error.localizedDescription)")
        }
      }
    }
  }

  private var safeAreaTop: CGFloat {
    UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0
  }
}
