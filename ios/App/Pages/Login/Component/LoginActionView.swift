import SwiftUI

struct LoginActionView: View {
  var canLogin: Bool
  var isWorking: Bool
  @Binding var isPasswordLogin: Bool
  var onTapLogin: () -> Void

  var body: some View {
    VStack(spacing: 16) {
      Button {
        UIApplication.shared.dismissKeyboard()
        onTapLogin()
      } label: {
        ZStack {
          RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.3)) // Disabled state color mostly
            .overlay(
              RoundedRectangle(cornerRadius: 8)
                .fill(
                  Color(
                    red: 0x06 / 255.0, green: 0xBA / 255.0,
                    blue: 0xFF / 255.0
                  )
                )
                .opacity(canLogin ? 1 : 0.3)
            )
            .frame(height: 50)

          if isWorking {
            ProgressView()
              .tint(.white)
          } else {
            Text("登录")
              .font(.system(size: 16, weight: .bold))
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
        Text(isPasswordLogin ? "验证码登录" : "密码登录")
          .font(.system(size: 16, weight: .medium))
          .foregroundColor(Color(hex: "0x585858"))
          .frame(maxWidth: .infinity)
          .frame(height: 50)
          .background(
            RoundedRectangle(cornerRadius: 8)
              .stroke(Color.gray.opacity(0.2), lineWidth: 1)
          )
      }
    }
    .padding(.horizontal, 30)
  }
}
