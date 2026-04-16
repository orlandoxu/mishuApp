import SwiftUI

struct LoginActionView: View {
  var canLogin: Bool
  var isWorking: Bool
  @Binding var isPasswordLogin: Bool
  var onTapLogin: () -> Void

  var body: some View {
    VStack(spacing: 14) {
      Button {
        UIApplication.shared.dismissKeyboard()
        onTapLogin()
      } label: {
        ZStack {
          RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(
              LinearGradient(
                colors: [ThemeColor.brand600, ThemeColor.brand500],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
            .opacity(canLogin ? 1 : 0.45)
            .frame(height: 52)
            .shadow(color: ThemeColor.brand500.opacity(canLogin ? 0.35 : 0), radius: 12, x: 0, y: 8)

          if isWorking {
            ProgressView()
              .tint(.white)
          } else {
            Text("登录")
              .font(.system(size: 17, weight: .bold))
              .foregroundColor(.white)
          }
        }
      }
      .disabled(!canLogin || isWorking)

      Button {
        withAnimation {
          isPasswordLogin.toggle()
        }
      } label: {
        HStack(spacing: 6) {
          Image(systemName: "arrow.triangle.2.circlepath")
            .font(.system(size: 12, weight: .bold))
          Text(isPasswordLogin ? "切换到验证码登录" : "切换到密码登录")
            .font(.system(size: 14, weight: .semibold))
        }
        .foregroundColor(Color(hex: "4B5563"))
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(
          Capsule(style: .continuous)
            .fill(Color.white.opacity(0.8))
            .overlay(
              Capsule(style: .continuous)
                .stroke(Color(hex: "D1D5DB"), lineWidth: 1)
            )
        )
      }
    }
  }
}
