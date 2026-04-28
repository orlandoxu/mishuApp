import SwiftUI

struct PaymentMethodRow: View {
  let title: String
  let subtitle: String
  let symbol: String
  let color: Color
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 14) {
        Image(systemName: symbol)
          .font(.system(size: 18, weight: .bold))
          .foregroundColor(color)
          .frame(width: 38, height: 38)
          .background(Color.white)
          .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
          .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)

        VStack(alignment: .leading, spacing: 4) {
          Text(title)
            .font(.system(size: 15, weight: .black))
            .foregroundColor(.black)
          Text(subtitle)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.black.opacity(0.30))
        }

        Spacer()

        ZStack {
          Circle()
            .stroke(isSelected ? color : Color.black.opacity(0.08), lineWidth: 2)
            .frame(width: 22, height: 22)
          if isSelected {
            Circle()
              .fill(color)
              .frame(width: 22, height: 22)
            Image(systemName: "checkmark")
              .font(.system(size: 10, weight: .black))
              .foregroundColor(.white)
          }
        }
      }
      .padding(16)
      .background(isSelected ? Color.black.opacity(0.03) : Color.white.opacity(0.2))
      .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
    .buttonStyle(.plain)
  }
}
