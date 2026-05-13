import SwiftUI

struct MoneyWeekPickerSheet: View {
  @Binding var selectedDate: Date
  let budgetMode: String

  @State private var visibleMonth: Date
  @State private var isSelectingYear = false
  @State private var yearGridStart: Int

  init(selectedDate: Binding<Date>, budgetMode: String) {
    _selectedDate = selectedDate
    self.budgetMode = budgetMode
    let month = selectedDate.wrappedValue.moneyJarMonthStart
    _visibleMonth = State(initialValue: month)
    _yearGridStart = State(initialValue: (Calendar.current.component(.year, from: month) / 12) * 12)
  }

  private let calendar = Calendar.moneyJar
  private let weekdays = ["一", "二", "三", "四", "五", "六", "日"]

  private var title: String {
    if isSelectingYear {
      return "\(yearGridStart)年 - \(yearGridStart + 11)年"
    }
    let comps = calendar.dateComponents([.year, .month], from: visibleMonth)
    return String(format: "%04d年%02d月", comps.year ?? 0, comps.month ?? 1)
  }

  private var weeks: [[Date]] {
    guard let first = calendar.date(from: calendar.dateComponents([.year, .month], from: visibleMonth)) else { return [] }
    let start = first.moneyJarWeekStart
    return (0..<6).map { weekIndex in
      (0..<7).compactMap { dayIndex in
        calendar.date(byAdding: .day, value: weekIndex * 7 + dayIndex, to: start)
      }
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        navButton(symbol: "chevron.left") {
          if isSelectingYear {
            yearGridStart -= 12
          } else {
            visibleMonth = calendar.date(byAdding: .month, value: -1, to: visibleMonth) ?? visibleMonth
          }
        }

        Spacer()

        Button {
          withAnimation(.easeInOut(duration: 0.18)) {
            isSelectingYear.toggle()
          }
        } label: {
          Text(title)
            .font(.system(size: 17, weight: .black))
            .foregroundColor(Color.black.opacity(0.80))
        }
        .buttonStyle(.plain)

        Spacer()

        navButton(symbol: "chevron.right") {
          if isSelectingYear {
            yearGridStart += 12
          } else {
            visibleMonth = calendar.date(byAdding: .month, value: 1, to: visibleMonth) ?? visibleMonth
          }
        }
      }
      .padding(.horizontal, 8)
      .padding(.bottom, 28)

      if isSelectingYear {
        yearGrid
      } else {
        calendarGrid
      }
    }
    .padding(.horizontal, 24)
    .padding(.top, 28)
    .padding(.bottom, 42)
    .frame(maxWidth: .infinity)
    .background(Color.white)
    .clipShape(RoundedCorner(radius: 32, corners: [.topLeft, .topRight]))
    .shadow(color: Color.black.opacity(0.18), radius: 32, x: 0, y: -8)
    .onAppear {
      visibleMonth = selectedDate.moneyJarMonthStart
      yearGridStart = (calendar.component(.year, from: selectedDate) / 12) * 12
      isSelectingYear = false
    }
  }

  private var yearGrid: some View {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
      ForEach(0..<12, id: \.self) { index in
        let year = yearGridStart + index
        Button {
          visibleMonth = visibleMonth.settingMoneyJarYear(year)
          withAnimation(.easeInOut(duration: 0.18)) {
            isSelectingYear = false
          }
        } label: {
          Text("\(year)")
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(year == calendar.component(.year, from: visibleMonth) ? .white : Color.black.opacity(0.80))
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(year == calendar.component(.year, from: visibleMonth) ? Color.black : Color(hex: "#F8F9FB"))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.horizontal, 2)
    .frame(minHeight: 300, alignment: .top)
  }

  private var calendarGrid: some View {
    VStack(spacing: 10) {
      HStack {
        ForEach(weekdays, id: \.self) { day in
          Text(day)
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(Color.black.opacity(0.40))
            .frame(maxWidth: .infinity)
        }
      }
      .padding(.bottom, 4)

      VStack(spacing: 4) {
        ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
          weekRow(week)
        }
      }
    }
    .frame(minHeight: 300, alignment: .top)
  }

  private func weekRow(_ week: [Date]) -> some View {
    let isSelected = week.contains { calendar.isDate($0, inSameDayAs: selectedDate.moneyJarWeekStart) }

    return Button {
      selectedDate = week[0]
      BottomSheetCenter.shared.hide()
    } label: {
      ZStack {
        if isSelected {
          RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color(hex: "#F4F4F5"))
            .overlay(
              RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
        }

        HStack(spacing: 0) {
          ForEach(week, id: \.self) { day in
            dayCell(day, isSelected: isSelected)
          }
        }
        .padding(.vertical, 6)
      }
      .frame(height: 56)
    }
    .buttonStyle(.plain)
  }

  private func dayCell(_ day: Date, isSelected: Bool) -> some View {
    let isCurrentMonth = calendar.isDate(day, equalTo: visibleMonth, toGranularity: .month)
    let isToday = calendar.isDateInToday(day)
    let amount = day.moneyJarMockAmount(mode: budgetMode)

    return VStack(spacing: 1) {
      Text("\(calendar.component(.day, from: day))")
        .font(.system(size: 14, weight: .bold))
        .foregroundColor(dayTextColor(isSelected: isSelected, isCurrentMonth: isCurrentMonth, isToday: isToday))
        .frame(width: 28, height: 28)
        .background(todayBackground(isSelected: isSelected, isToday: isToday))
        .clipShape(Circle())
        .overlay(
          Circle()
            .stroke(isToday && isSelected ? Color.black.opacity(0.05) : .clear, lineWidth: 1)
        )

      if let amount, isCurrentMonth {
        Text("\(budgetMode == "expense" ? "-" : "+")\(amount)")
          .font(.system(size: 9, weight: .bold))
          .foregroundColor(budgetMode == "expense" ? Color(hex: "#FF7A7A") : Color(hex: "#00D084"))
          .tracking(-0.4)
      } else {
        Text(" ")
          .font(.system(size: 9, weight: .bold))
      }
    }
    .frame(maxWidth: .infinity)
  }

  private func dayTextColor(isSelected: Bool, isCurrentMonth: Bool, isToday: Bool) -> Color {
    if isToday && !isSelected { return .white }
    if isToday && isSelected { return Color(hex: "#FF7A7A") }
    if isSelected { return .black }
    return isCurrentMonth ? Color.black.opacity(0.80) : Color.black.opacity(0.20)
  }

  @ViewBuilder
  private func todayBackground(isSelected: Bool, isToday: Bool) -> some View {
    if isToday && !isSelected {
      Color.black
    } else if isToday && isSelected {
      Color.white
    } else {
      Color.clear
    }
  }

  private func navButton(symbol: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Image(systemName: symbol)
        .font(.system(size: 22, weight: .semibold))
        .foregroundColor(Color.black.opacity(0.60))
        .frame(width: 40, height: 40)
        .background(Color.black.opacity(0.001))
        .clipShape(Circle())
    }
    .buttonStyle(.plain)
  }
}
