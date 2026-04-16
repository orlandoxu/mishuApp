import SwiftUI

struct LoginBackgroundView: View {
  var body: some View {
    ZStack {
      LinearGradient(
        colors: [Color(hex: "EAF7FF"), Color(hex: "F8FBFF"), Color.white],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      Circle()
        .fill(Color(hex: "95DEFF").opacity(0.25))
        .frame(width: 260, height: 260)
        .blur(radius: 8)
        .offset(x: -120, y: -290)

      Circle()
        .fill(Color(hex: "7CC4FF").opacity(0.20))
        .frame(width: 300, height: 300)
        .blur(radius: 12)
        .offset(x: 140, y: -220)

      Image("background")
        .resizable()
        .scaledToFit()
        .frame(maxWidth: .infinity)
        .opacity(0.22)
        .offset(y: -180)
        .ignoresSafeArea(edges: .top)
    }
  }
}
