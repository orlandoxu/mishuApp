import SwiftUI

struct FoodMemoryMonthSlider: View {
  let months: [String]
  let selectedMonth: String?
  let monthStats: [String: Int]
  let fallbackCountForMonth: (String) -> Int
  let onSelectMonth: (String?) -> Void

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 10) {
        ForEach(months, id: \.self) { month in
          let selected = selectedMonth == month
          let count = monthStats[month] ?? fallbackCountForMonth(month)

          Button {
            onSelectMonth(selected ? nil : month)
          } label: {
            VStack(spacing: 6) {
              Text(month)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(selected ? Color.white.opacity(0.6) : Color.black.opacity(0.35))
              Text("\(count)店")
                .font(.system(size: 14, weight: .black))
                .foregroundColor(selected ? .white : Color.black.opacity(0.8))
            }
            .frame(width: 78, height: 74)
            .background(selected ? Color.black.opacity(0.82) : Color.white.opacity(0.62))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
              RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.black.opacity(selected ? 0 : 0.06), lineWidth: 1)
            )
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier("food_memory_month_\(month.replacingOccurrences(of: "/", with: "_"))")
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 12)
    }
    .background(Color.white.opacity(0.56))
    .overlay(alignment: .top) {
      Rectangle().fill(Color.black.opacity(0.04)).frame(height: 1)
    }
  }
}
