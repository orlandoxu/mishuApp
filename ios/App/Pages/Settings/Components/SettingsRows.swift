import SwiftUI

struct SettingsRow: View {
  let symbol: String
  let symbolColor: Color
  let title: String
  let value: String?

  init(symbol: String, symbolColor: Color, title: String, value: String? = nil) {
    self.symbol = symbol
    self.symbolColor = symbolColor
    self.title = title
    self.value = value
  }

  var body: some View {
    HStack(spacing: 14) {
      Image(systemName: symbol)
        .font(.system(size: 17, weight: .semibold))
        .foregroundColor(symbolColor)
        .frame(width: 28, height: 28)
        .background(Color.black.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

      Text(title)
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(Color.black.opacity(0.80))

      Spacer()

      if let value {
        Text(value)
          .font(.system(size: 15, weight: .medium))
          .foregroundColor(Color.black.opacity(0.40))
      }

      Image(systemName: "chevron.right")
        .font(.system(size: 13, weight: .bold))
        .foregroundColor(Color.black.opacity(0.20))
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .background(Color.white)
  }
}

struct SettingsGroup<Content: View>: View {
  let title: String
  let content: Content

  init(title: String, @ViewBuilder content: () -> Content) {
    self.title = title
    self.content = content()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.system(size: 13, weight: .medium))
        .foregroundColor(Color.black.opacity(0.40))
        .padding(.leading, 16)
      VStack(spacing: 0) {
        content
      }
      .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 20, style: .continuous)
          .stroke(Color.black.opacity(0.05), lineWidth: 1)
      )
      .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
    }
  }
}
