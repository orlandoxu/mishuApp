import SwiftUI

struct TCardDateSelectorView: View {
  let dates: [Date]
  let selectedDate: Date
  let onSelect: (Date) -> Void

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 12) {
        if dates.isEmpty {
          Text("暂无日期数据")
            .font(.system(size: 14))
            .foregroundColor(.gray)
            .padding(.horizontal, 20)
        } else {
          ForEach(dates, id: \.self) { date in
            let isSelected = Calendar.current.isDate(selectedDate, inSameDayAs: date)
            Button(action: { onSelect(date) }) {
              Text(title(for: date))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : Color(hex: "0x333333"))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? ThemeColor.brand500 : Color(hex: "0xF5F5F5"))
                .cornerRadius(4)
            }
            .buttonStyle(.plain)
          }
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 10)
    }
    .background(Color.white)
  }

  private func title(for date: Date) -> String {
    if Calendar.current.isDateInToday(date) { return "今天" }
    let formatter = DateFormatter()
    formatter.dateFormat = "MM-dd"
    return formatter.string(from: date)
  }
}
