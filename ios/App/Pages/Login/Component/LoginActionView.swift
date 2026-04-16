import SwiftUI

struct LoginActionView: View {
  var canLogin: Bool
  var isWorking: Bool
  var onTapLogin: () -> Void
  var onTapWeChatLogin: () -> Void

  var body: some View {
    VStack(spacing: 18) {
      Button {
        UIApplication.shared.dismissKeyboard()
        onTapLogin()
      } label: {
        ZStack {
          RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(
              LinearGradient(
                colors: [Color(hex: "FF7B84"), Color(hex: "FF696F")],
                startPoint: .leading,
                endPoint: .trailing
              )
            )
            .opacity(canLogin ? 1 : 0.45)
            .frame(height: 58)
            .shadow(color: Color(hex: "FF6B6B").opacity(canLogin ? 0.18 : 0), radius: 12, x: 0, y: 10)

          if isWorking {
            ProgressView()
              .tint(.white)
          } else {
            HStack(spacing: 6) {
              Text("登录 / 注册")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
              Image(systemName: "arrow.right")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))
            }
          }
        }
      }
      .disabled(!canLogin || isWorking)

      HStack(spacing: 12) {
        Rectangle()
          .fill(Color.black.opacity(0.05))
          .frame(height: 1)
        Text("其他登录方式")
          .font(.system(size: 13, weight: .regular))
          .foregroundColor(Color.black.opacity(0.3))
        Rectangle()
          .fill(Color.black.opacity(0.05))
          .frame(height: 1)
      }
      .padding(.top, 10)

      Button {
        UIApplication.shared.dismissKeyboard()
        onTapWeChatLogin()
      } label: {
        HStack(spacing: 8) {
          Image("icon_logo_wechat")
            .resizable()
            .renderingMode(.original)
            .scaledToFit()
            .frame(width: 20, height: 20)
          Text("通过微信登录")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(Color.black.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 58)
        .background(
          RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Color.white)
            .overlay(
              RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color(hex: "ECECF1"), lineWidth: 1)
            )
        )
        .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
      }
    }
  }
}
