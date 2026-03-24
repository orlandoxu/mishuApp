import SwiftUI

struct CarInfoStep3View: View {
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
        .padding(.horizontal, 16)
        .frame(height: 56 + safeAreaTop)

        ScrollView {
          VStack(alignment: .leading, spacing: 32) {
            // Car Model Selection
            VStack(alignment: .leading, spacing: 10) {
              Text("车型选择")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(Color(hex: "0x333333"))
                .padding(.top, 40)

              Button {
                appNavigation.push(.carBrandSelection())
              } label: {
                HStack {
                  Text(bindingStore.carBrandName.isEmpty ? "请选择" : "\(bindingStore.carBrandName) \(bindingStore.carSeriesName)")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color(hex: "0x111111"))

                  Spacer()

                  Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(hex: "0x999999"))
                }
                .padding(.horizontal, 16)
                .frame(height: 50)
                .background(
                  RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(hex: "0xE5E5E5"), lineWidth: 1)
                )
                .contentShape(Rectangle())
              }
              .buttonStyle(.plain)
            }

            // Next Button
            Button {
              goToNextStep()
            } label: {
              ZStack {
                RoundedRectangle(cornerRadius: 8)
                  .fill(canSubmit ? Color(hex: "0x06BAFF") : Color(hex: "0x06BAFF").opacity(0.6))

                Text("下一步")
                  .font(.system(size: 16, weight: .semibold))
                  .foregroundColor(.white)
              }
              .frame(height: 50)
            }
            .buttonStyle(.plain)
            .disabled(!canSubmit)
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

  private var canSubmit: Bool {
    bindingStore.seriesId != 0
  }

  private func goToNextStep() {
    if let next = bindingStore.nextStepNumber(after: 3) {
      appNavigation.push(bindingStore.enterStep(next))
      return
    }
    submitBinding()
  }

  private func submitBinding() {
    Task {
      let success = await bindingStore.submitBinding()
      await MainActor.run {
        if success {
          ToastCenter.shared.show("绑定成功")
          appNavigation.root = .mainTab(.recorder)
        } else {
          ToastCenter.shared.show("绑定失败，请稍后再试")
        }
      }
    }
  }

  private var safeAreaTop: CGFloat {
    UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0
  }
}
