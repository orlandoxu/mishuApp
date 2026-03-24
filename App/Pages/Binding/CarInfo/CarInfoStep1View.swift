import SwiftUI

struct CarInfoStep1View: View {
  @ObservedObject private var appNavigation = AppNavigationModel.shared
  @StateObject private var bindingStore: BindingStore = .shared

  /// 8位车牌数组
  @State private var chars: [String] = Array(repeating: "", count: 8)
  /// 当前光标位置 (0-7)
  @State private var currentIndex: Int = 0

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

        // Content
        ScrollView {
          VStack(alignment: .leading, spacing: 32) {
            Text("请输入车牌号码，以便享受更精准的服务")
              .font(.system(size: 16, weight: .regular))
              .foregroundColor(Color(hex: "0x333333"))
              .padding(.top, 40)

            // 自定义输入框组件
            LicensePlateInputView(
              chars: chars,
              currentIndex: currentIndex,
              onTapIndex: { index in
                currentIndex = index
              }
            )
            .frame(maxWidth: .infinity) // 居中

            // Next Button
            Button {
              submit()
            } label: {
              ZStack {
                RoundedRectangle(cornerRadius: 8)
                  .fill(canSubmit ? ThemeColor.brand500 : ThemeColor.brand500.opacity(0.6))

                Text("下一步")
                  .font(.system(size: 16, weight: .semibold))
                  .foregroundColor(.white)
              }
              .frame(height: 50)
            }
            .buttonStyle(.plain)
            .disabled(!canSubmit)
            .padding(.top, 20)

            Spacer(minLength: 50)
          }
          .padding(.horizontal, 24)
        }

        // Keyboard Area
        // 放在底部，无缝衔接
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
        .background(Color(hex: "0xD1D5DB"))
      }
    }
    .ignoresSafeArea(edges: .bottom)
    .navigationBarHidden(true)
    .navigationBarBackButtonHidden(true)
    .onAppear {
      bindingStore.updateCurrentStep(for: 1)
      initializeChars()
    }
  }

  // MARK: - Logic

  private var canSubmit: Bool {
    // 检查前7位是否都有值
    for i in 0 ..< 7 {
      if chars[i].isEmpty { return false }
    }
    return true
  }

  private func initializeChars() {
    let province = bindingStore.province
    let licensePlate = bindingStore.licensePlate

    // 初始化省份
    if !province.isEmpty {
      chars[0] = String(province.prefix(1))
    }

    // 初始化号码
    let plateArr = Array(licensePlate).map { String($0) }
    for (i, char) in plateArr.enumerated() {
      if i + 1 < 8 {
        chars[i + 1] = char
      }
    }

    // 设置初始光标位置
    if province.isEmpty {
      currentIndex = 0
    } else {
      // 省份有值，看号码
      if licensePlate.isEmpty {
        currentIndex = 1
      } else {
        let nextIndex = licensePlate.count + 1
        currentIndex = min(nextIndex, 7)
      }
    }
  }

  private func handleInput(_ text: String) {
    if currentIndex >= 8 { return }

    // 设置当前位
    chars[currentIndex] = text

    // 更新 store
    updateStore()

    // 移动光标
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
    updateStore()
  }

  private func handleClear() {
    chars = Array(repeating: "", count: 8)
    currentIndex = 0
    updateStore()
  }

  private func updateStore() {
    // 省份
    if !chars[0].isEmpty {
      bindingStore.province = chars[0]
    } else {
      bindingStore.province = ""
    }

    // 号码 (从 index 1 开始拼接)
    let platePart = chars.dropFirst().joined()
    bindingStore.licensePlate = platePart
  }

  private func submit() {
    goToNextStep()
  }

  private func goToNextStep() {
    if let next = bindingStore.nextStepNumber(after: 1) {
      appNavigation.push(bindingStore.enterStep(next))
    }
  }

  private var safeAreaTop: CGFloat {
    UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0
  }

  private var safeAreaBottom: CGFloat {
    UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
  }
}
