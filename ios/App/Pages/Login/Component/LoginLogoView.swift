import SwiftUI

struct LoginLogoView: View {
  var body: some View {
    VStack(spacing: 14) {
      if UIImage(named: "AppLogo") != nil {
        Image("AppLogo")
          .resizable()
          .scaledToFit()
          .frame(width: 92, height: 92)
          .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
          .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
      } else {
        ZStack {
          RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(
              LinearGradient(
                colors: [Color(hex: "06BAFF"), Color(hex: "0098D9")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
            .frame(width: 92, height: 92)
          Image(systemName: "cloud.fill")
            .font(.system(size: 38))
            .foregroundColor(.white)
        }
      }

      Text("欢迎回来")
        .font(.system(size: 30, weight: .bold))
        .foregroundColor(Color(hex: "1F2A37"))

      Text("登录后即可继续使用米树助手")
        .font(.system(size: 14, weight: .medium))
        .foregroundColor(Color(hex: "6B7280"))
    }
    .padding(.bottom, 8)
  }
}
