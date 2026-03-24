import SwiftUI

struct QualityPopupView: View {
  let currentQuality: LiveVideoQuality
  let onSelect: (LiveVideoQuality) -> Void

  var body: some View {
    VStack(spacing: 0) {
      ForEach(LiveVideoQuality.allCases) { item in
        Button {
          onSelect(item)
        } label: {
          Text(item.rawValue)
            .font(.system(size: 13, weight: item == currentQuality ? .semibold : .regular))
            .foregroundColor(item == currentQuality ? Color(hex: "#00BFFF") : .white)
            .padding(.vertical, 10)
            .frame(width: 70)
        }
        .buttonStyle(.plain)

        if item != LiveVideoQuality.allCases.last {
          Divider()
            .background(Color.white.opacity(0.2))
        }
      }
    }
    .background(Color.black.opacity(0.85))
    .cornerRadius(8)
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
    )
  }
}
