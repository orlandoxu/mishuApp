import SwiftUI

struct NicknameEditView: View {
  @ObservedObject private var appNavigation = AppNavigationModel.shared
  @StateObject private var selfStore: SelfStore = .shared
  @State private var nickname: String = ""
  @State private var isLoading = false

  var disabled: Bool {
    isLoading || nickname.isEmpty
  }

  var body: some View {
    VStack(spacing: 0) {
      // Spacer().frame(height: safeAreaTop).background(Color.white)
      NavHeader(title: "修改昵称")

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
    .onTapGesture {
      UIApplication.shared.dismissKeyboard()
    }
    .navigationBarHidden(true)
    .onAppear {
      nickname = selfStore.selfUser?.nickname ?? ""
    }
    .overlay(
      Group {
        if isLoading {
          ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
            ProgressView()
              .padding()
              .background(Color.white)
              .cornerRadius(8)
          }
        }
      }
    )
  }

  private func save() {
    guard !nickname.isEmpty else { return }
    isLoading = true

    Task {
      let selfUser = await UserAPI.shared.updateNickname(nickname)
      await MainActor.run {
        isLoading = false
        if let selfUser {
          selfStore.selfUser = selfUser
          appNavigation.pop()
        }
      }
    }
  }

  private var safeAreaTop: CGFloat {
    UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0
  }
}
