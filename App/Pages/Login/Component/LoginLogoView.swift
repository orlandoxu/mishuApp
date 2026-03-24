import SwiftUI

struct LoginLogoView: View {
  var body: some View {
    VStack(spacing: 16) {
      // Try to load "logo", fallback to "AppIcon", then fallback to system symbol
      if UIImage(named: "AppLogo") != nil {
        Image("AppLogo")
          .resizable()
          .scaledToFit()
          .frame(width: 100, height: 100)
          .cornerRadius(16)
      } else {
        ZStack {
          RoundedRectangle(cornerRadius: 16)
            .fill(
              Color(
                red: 0x06 / 255.0, green: 0xBA / 255.0, blue: 0xFF / 255.0
              )
            )
            .frame(width: 80, height: 80)
          Image(systemName: "cloud.fill")
            .font(.system(size: 40))
            .foregroundColor(.white)
        }
      }
    }
    .padding(.bottom, 60)
  }
}
