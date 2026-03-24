import SwiftUI

struct ManualBindView: View {
  @ObservedObject private var appNavigation = AppNavigationModel.shared
  @ObservedObject private var viewModel: BindingStore = .shared

  var body: some View {
    ZStack {
      LoginBackgroundView()

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

          Text("绑定验证")
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(Color(hex: "0x111111"))
            .padding(.leading, 4)

          Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .frame(height: 56 + safeAreaTop)

        ScrollView {
          VStack(alignment: .leading, spacing: 24) {
            Text("请输入设备背面的IMEI码和SN码进行验证。")
              .font(.system(size: 14, weight: .regular))
              .foregroundColor(Color(hex: "0x666666"))
              .padding(.top, 12)

            // IMEI Input
            VStack(alignment: .leading, spacing: 10) {
              Text("IMEI码")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "0x111111"))

              UIKitTextField(
                titleKey: "请输入15位IMEI码",
                text: $viewModel.imeiText,
                keyboardType: .asciiCapableNumberPad,
                autocapitalizationType: .none,
                autocorrectionDisabled: true
              )
              .onChange(of: viewModel.imeiText) { newValue in
                let limited = String(newValue.prefix(15))
                if limited != newValue {
                  viewModel.imeiText = limited
                }
              }
              .padding(.horizontal, 16)
              .frame(height: 52)
              .background(
                RoundedRectangle(cornerRadius: 8)
                  .stroke(Color(hex: "0xE5E5E5"), lineWidth: 1)
              )
            }

            // SN Input
            VStack(alignment: .leading, spacing: 10) {
              Text("SN码")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "0x111111"))

              UIKitTextField(
                titleKey: "请输入15位SN码",
                text: $viewModel.snText,
                // keyboardType: .default,
                // 新项目目前R1，SN码仅支持数字输入
                keyboardType: .asciiCapableNumberPad,
                autocapitalizationType: .none,
                autocorrectionDisabled: true
              )
              .onChange(of: viewModel.snText) { newValue in
                let limited = String(newValue.prefix(15))
                if limited != newValue {
                  viewModel.snText = limited
                }
              }
              .padding(.horizontal, 16)
              .frame(height: 52)
              .background(
                RoundedRectangle(cornerRadius: 8)
                  .stroke(Color(hex: "0xE5E5E5"), lineWidth: 1)
              )
            }

            Button {
              checkBindStatus()
            } label: {
              ZStack {
                // DONE-AI: 修复点击空白处收起键盘导致 TextField 无法输入（改为 gesture including: .gesture）
                RoundedRectangle(cornerRadius: 8)
                  .fill(viewModel.canSubmitManual ? ThemeColor.brand500 : ThemeColor.brand500.opacity(0.4)) // Based on screenshot color

                if viewModel.isChecking {
                  ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                  Text("下一步")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                }
              }
              .frame(height: 50)
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canSubmitManual || viewModel.isChecking)
            .padding(.top, 20)

            Spacer(minLength: 0)
          }
          .padding(.horizontal, 24)
        }
      }
    }
    .onTapGesture {
      UIApplication.shared.dismissKeyboard()
    }
  }

  private func checkBindStatus() {
    // Step 1. 收起键盘，避免 push 过程中焦点切换产生额外布局刷新
    UIApplication.shared.dismissKeyboard()

    // Step 2. 发起校验请求（主线程隔离，保证状态更新一致）
    Task { @MainActor in
      let success = await viewModel.checkBindStatus()
      // Step 3. 根据结果跳转或提示
      if success {
        // DONE-AI: 不允许自动绑定；必须进入步骤页由用户手动确认一次
        appNavigation.push(viewModel.recommendedNextStepRoute())
      }
    }
  }
}
