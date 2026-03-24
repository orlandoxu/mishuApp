import SwiftUI

struct QRCodeBindingHeaderView: View {
  let onBack: () -> Void

  var body: some View {
    HStack(spacing: 0) {
      Button {
        onBack()
      } label: {
        ZStack {
          Circle()
            .fill(Color.white.opacity(0.001))
            .frame(width: 44, height: 44)
          Image(systemName: "chevron.left")
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(.white)
        }
      }
      .buttonStyle(.plain)

      Spacer()
    }
    .frame(height: 56)
  }
}
