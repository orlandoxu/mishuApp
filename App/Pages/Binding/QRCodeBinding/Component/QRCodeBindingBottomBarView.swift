import SwiftUI

struct QRCodeBindingBottomBarView: View {
  let onTap: () -> Void

  var body: some View {
    Button {
      onTap()
    } label: {
      HStack(spacing: 12) {
        Text("未识别二维码？手动输入")
          .font(.system(size: 15, weight: .medium))
          .foregroundColor(Color.white.opacity(0.9))

        Spacer(minLength: 0)

        Image(systemName: "chevron.right")
          .font(.system(size: 14, weight: .semibold))
          .foregroundColor(Color.white.opacity(0.6))
      }
      .padding(.horizontal, 18)
      .frame(height: 56)
      .frame(maxWidth: .infinity)
      .background(Color(hex: "0x333333").opacity(0.8))
      .overlay(
        RoundedRectangle(cornerRadius: 16)
          .stroke(Color.white.opacity(0.05), lineWidth: 1)
      )
      .cornerRadius(16)
    }
    .buttonStyle(.plain)
  }
}
