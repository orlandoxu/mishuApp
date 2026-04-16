import SwiftUI

struct LoginLogoView: View {
  var body: some View {
    VStack(spacing: 22) {
      AuraMascotView(status: .idle)
      Text("你好，我是 Aura")
        .font(.system(size: 28, weight: .semibold))
        .foregroundColor(Color(hex: "1B1F2A"))
    }
    .padding(.bottom, 6)
  }
}
