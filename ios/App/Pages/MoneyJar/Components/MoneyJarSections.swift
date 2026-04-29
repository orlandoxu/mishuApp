import SwiftUI

struct MoneyTransaction: Identifiable {
  let id: String
  let type: String
  let amount: Int
  let category: String
  let date: String
  let note: String
}

struct MoneyWeekSelector: View {
  let title: String
  let onPrevious: () -> Void
  let onNext: () -> Void
  let onTap: () -> Void

  var body: some View {
    HStack {
      Button(action: onPrevious) {
        Image(systemName: "chevron.left")
          .font(.system(size: 22, weight: .bold))
          .foregroundColor(Color.black.opacity(0.24))
          .frame(width: 34, height: 34)
      }
      .buttonStyle(.plain)

      Spacer()

      Button(action: onTap) {
        HStack(spacing: 10) {
          Image(systemName: "calendar")
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(Color.black.opacity(0.60))
          Text(title)
            .font(.system(size: 16, weight: .black))
            .foregroundColor(Color.black.opacity(0.80))
        }
      }
      .buttonStyle(.plain)

      Spacer()

      Button(action: onNext) {
        Image(systemName: "chevron.right")
          .font(.system(size: 22, weight: .bold))
          .foregroundColor(Color.black.opacity(0.10))
          .frame(width: 34, height: 34)
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 12)
  }
}

struct MoneyBudgetCard: View {
  let mode: String
  let progress: Double
  let limit: Int
  let onToggle: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      ZStack(alignment: .top) {
        SemiCircleGauge(progress: min(max(progress, 0), 1), color: gaugeColor)
          .frame(width: 240, height: 135)

        VStack(spacing: 4) {
          Text(mode == "expense" ? "支出预算" : "收入目标")
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(Color.black.opacity(0.20))
            .tracking(2.2)
            .textCase(.uppercase)
            .padding(.leading, 8)

          Text("¥\(limit)")
            .font(.system(size: 36, weight: .black))
            .foregroundColor(.black)
            .tracking(-1.2)
            .minimumScaleFactor(0.72)
            .lineLimit(1)
        }
        .padding(.top, 62)
      }

      HStack(spacing: 8) {
        HStack(spacing: 8) {
          Circle()
            .fill(Color.black.opacity(0.02))
            .frame(width: 24, height: 24)
            .overlay(
              Image(systemName: "bell.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color.black.opacity(0.20))
            )
          Text("本周余额充值哦！")
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(Color.black.opacity(0.30))
        }

        Button(action: onToggle) {
          Text(mode == "expense" ? "收入目标" : "支出预算")
            .font(.system(size: 12, weight: .black))
            .foregroundColor(mode == "expense" ? Color(hex: "#43E6C1") : Color(hex: "#FFA3B1"))
        }
        .buttonStyle(.plain)
      }
      .padding(.top, 18)
    }
    .frame(maxWidth: .infinity)
  }

  private var gaugeColor: Color {
    mode == "expense" ? Color(hex: "#FFA3B1") : Color(hex: "#43E6C1")
  }
}

private struct SemiCircleGauge: View {
  let progress: Double
  let color: Color

  var body: some View {
    ZStack {
      GaugeArc(progress: 1)
        .stroke(Color(hex: "#F2F4F7"), style: StrokeStyle(lineWidth: 14, lineCap: .round))
      GaugeArc(progress: progress)
        .stroke(color, style: StrokeStyle(lineWidth: 14, lineCap: .round))
        .animation(.easeOut(duration: 0.8), value: progress)
    }
  }
}

private struct GaugeArc: Shape {
  let progress: Double

  func path(in rect: CGRect) -> Path {
    var path = Path()
    let center = CGPoint(x: rect.midX, y: rect.maxY - 15)
    let radius = min(rect.width / 2 - 20, rect.height - 20)
    path.addArc(
      center: center,
      radius: radius,
      startAngle: .degrees(180),
      endAngle: .degrees(180 + 180 * progress),
      clockwise: false
    )
    return path
  }
}

struct MoneyStatCards: View {
  let expense: Int
  let income: Int

  var body: some View {
    HStack(spacing: 16) {
      stat(title: "支出总计", value: expense, imageName: "img_money_income", symbol: "arrow.down.right", color: Color(hex: "#FF5778"))
      stat(title: "收入总计", value: income, imageName: "img_money_pay", symbol: "arrow.up.right", color: Color(hex: "#00D084"))
    }
  }

  private func stat(title: String, value: Int, imageName: String, symbol: String, color: Color) -> some View {
    ZStack(alignment: .topLeading) {
      Image(imageName)
        .resizable()
        .scaledToFill()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()

      VStack(alignment: .leading, spacing: 10) {
        HStack(spacing: 4) {
          Image(systemName: symbol)
            .font(.system(size: 12, weight: .black))
          Text(title)
            .font(.system(size: 10, weight: .black))
            .tracking(0.8)
            .textCase(.uppercase)
        }
        .foregroundColor(color)

        Text("¥\(value)")
          .font(.system(size: 26, weight: .black))
          .foregroundColor(.black)
          .tracking(-0.8)
      }
      .padding(.top, 24)
      .padding(.horizontal, 20)
    }
    .aspectRatio(24.0 / 15.0, contentMode: .fit)
    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 32, style: .continuous)
        .stroke(Color.white.opacity(0.50), lineWidth: 1)
    )
    .shadow(color: color.opacity(0.10), radius: 32, x: 0, y: 12)
  }
}

struct MoneyTransactionList: View {
  let transactions: [MoneyTransaction]

  var body: some View {
    VStack(spacing: 16) {
      HStack {
        Text("流水记录")
          .font(.system(size: 17, weight: .black))
          .foregroundColor(Color.black.opacity(0.90))
        Spacer()
        HStack(spacing: 4) {
          Text("查看详情")
          Image(systemName: "chevron.right")
        }
        .font(.system(size: 13, weight: .bold))
        .foregroundColor(Color.black.opacity(0.30))
      }
      .padding(.horizontal, 4)

      VStack(spacing: 12) {
        ForEach(transactions) { item in
          HStack(spacing: 20) {
            Text(transactionEmoji(for: item.category))
              .font(.system(size: 24))
              .frame(width: 56, height: 56)
              .background(transactionBackground(for: item.category))
              .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
              Text(item.category)
                .font(.system(size: 16, weight: .black))
                .foregroundColor(Color.black.opacity(0.80))
              Text("\(item.date) · \(item.note)")
                .font(.system(size: 13, weight: .black))
                .foregroundColor(Color.black.opacity(0.20))
                .tracking(-0.2)
            }

            Spacer()

            Text("\(item.type == "expense" ? "-" : "+")\(item.amount)")
              .font(.system(size: 20, weight: .black))
              .foregroundColor(item.type == "expense" ? Color.black.opacity(0.90) : Color(hex: "#00D084"))
          }
          .padding(20)
          .background(Color.white)
          .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
          .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
              .stroke(Color.black.opacity(0.01), lineWidth: 1)
          )
          .shadow(color: Color.black.opacity(0.02), radius: 24, x: 0, y: 8)
        }
      }
    }
    .padding(.top, 4)
  }

  private func transactionEmoji(for category: String) -> String {
    switch category {
    case "餐饮":
      return "🍔"
    case "交通":
      return "🚌"
    default:
      return "📦"
    }
  }

  private func transactionBackground(for category: String) -> Color {
    switch category {
    case "餐饮":
      return Color(hex: "#FFF2F4")
    case "交通":
      return Color(hex: "#F2F8FF")
    default:
      return Color.black.opacity(0.03)
    }
  }
}

struct MoneySettingsSheet: View {
  @Binding var budgetMode: String
  @Binding var budgetLimit: Int
  @Binding var incomeGoal: Int

  private var currentLimit: Int {
    budgetMode == "expense" ? budgetLimit : incomeGoal
  }

  private var limitStep: Int {
    switch currentLimit {
    case ..<100:
      return 10
    case ..<1_000:
      return 50
    case ..<10_000:
      return 500
    default:
      var upperBound = 100_000
      var step = 5_000
      while currentLimit >= upperBound {
        upperBound *= 10
        step *= 10
      }
      return step
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      VStack(alignment: .leading, spacing: 32) {
        VStack(alignment: .leading, spacing: 16) {
          Text("显示模式")
            .font(.system(size: 17, weight: .black))
            .foregroundColor(Color.black.opacity(0.80))
            .padding(.leading, 4)

          HStack(spacing: 4) {
            modeButton(title: "支出预算", mode: "expense")
            modeButton(title: "收入目标", mode: "income")
          }
          .padding(6)
          .background(Color(hex: "#F8F9FB"))
          .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }

        VStack(alignment: .leading, spacing: 18) {
          Text(budgetMode == "expense" ? "单周支出上限" : "单周收入目标")
            .font(.system(size: 17, weight: .black))
            .foregroundColor(Color.black.opacity(0.80))
            .padding(.leading, 4)

          HStack {
            stepButton(symbol: "minus") {
              updateLimit(max(0, currentLimit - limitStep))
            }

            Spacer()

            HStack(alignment: .firstTextBaseline, spacing: 6) {
              Text("¥")
                .font(.system(size: 34, weight: .black))
                .foregroundColor(Color.black.opacity(0.90))
                .layoutPriority(1)
              TextField("", text: limitText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.leading)
                .font(.system(size: 34, weight: .black))
                .foregroundColor(Color.black.opacity(0.90))
                .tracking(-1.2)
                .frame(width: 138, alignment: .leading)
                .textFieldStyle(.plain)
                .background(Color.clear)
            }
            .frame(width: 184, alignment: .center)

            Spacer()

            stepButton(symbol: "plus") {
              updateLimit(currentLimit + limitStep)
            }
          }
        }
      }

      Button {
        closeSheet()
      } label: {
        Text("保存并返回")
          .font(.system(size: 17, weight: .bold))
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .frame(height: 64)
          .background(Color.black)
          .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
      }
      .buttonStyle(.plain)
      .padding(.top, 40)
    }
    .padding(.horizontal, 32)
    .padding(.vertical, 32)
    .frame(maxWidth: 342)
    .background(Color.white)
    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
    .shadow(color: Color.black.opacity(0.18), radius: 36, x: 0, y: 12)
  }

  private var limitText: Binding<String> {
    Binding(
      get: { "\(currentLimit)" },
      set: { newValue in
        let digits = newValue.filter(\.isNumber)
        updateLimit(Int(digits) ?? 0)
      }
    )
  }

  private func modeButton(title: String, mode: String) -> some View {
    Button {
      budgetMode = mode
    } label: {
      Text(title)
        .font(.system(size: 14, weight: .black))
        .foregroundColor(budgetMode == mode ? .black : Color.black.opacity(0.20))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(budgetMode == mode ? Color.white : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: budgetMode == mode ? Color.black.opacity(0.04) : .clear, radius: 4, x: 0, y: 2)
    }
    .buttonStyle(.plain)
  }

  private func stepButton(symbol: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Image(systemName: symbol)
        .font(.system(size: 24, weight: .semibold))
        .foregroundColor(Color.black.opacity(0.60))
        .frame(width: 50, height: 50)
        .background(Color(hex: "#F8F9FB"))
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(
          RoundedRectangle(cornerRadius: 15, style: .continuous)
            .stroke(Color.black.opacity(0.02), lineWidth: 1)
        )
    }
    .buttonStyle(.plain)
  }

  private func updateLimit(_ value: Int) {
    if budgetMode == "expense" {
      budgetLimit = value
    } else {
      incomeGoal = value
    }
  }

  private func closeSheet() {
    BottomSheetCenter.shared.hide()
  }
}

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

extension Calendar {
  static var moneyJar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.firstWeekday = 2
    return calendar
  }
}

extension Date {
  static var mishuMoneyJarSeed: Date {
    Calendar.moneyJar.date(from: DateComponents(year: 2024, month: 4, day: 24)) ?? Date()
  }

  var moneyJarMonthStart: Date {
    Calendar.moneyJar.date(from: Calendar.moneyJar.dateComponents([.year, .month], from: self)) ?? self
  }

  var moneyJarWeekStart: Date {
    Calendar.moneyJar.dateInterval(of: .weekOfYear, for: self)?.start ?? self
  }

  var moneyJarWeekTitle: String {
    let calendar = Calendar.moneyJar
    let start = moneyJarWeekStart
    let end = calendar.date(byAdding: .day, value: 6, to: start) ?? start
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateFormat = "MM.dd"

    if calendar.isDate(start, inSameDayAs: Date.mishuMoneyJarSeed.moneyJarWeekStart) {
      return "\(formatter.string(from: start)) - \(formatter.string(from: end)) (本周)"
    }
    if let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: Date.mishuMoneyJarSeed),
       calendar.isDate(start, inSameDayAs: lastWeek.moneyJarWeekStart) {
      return "\(formatter.string(from: start)) - \(formatter.string(from: end)) (上周)"
    }
    return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
  }

  func addingMoneyJarWeeks(_ value: Int) -> Date {
    Calendar.moneyJar.date(byAdding: .weekOfYear, value: value, to: self) ?? self
  }

  func settingMoneyJarYear(_ year: Int) -> Date {
    var comps = Calendar.moneyJar.dateComponents([.month, .day], from: self)
    comps.year = year
    return Calendar.moneyJar.date(from: comps) ?? self
  }

  func moneyJarMockAmount(mode: String) -> Int? {
    let dayNumber = Int(timeIntervalSince1970 / 86_400)
    let raw = abs(sin(Double(dayNumber)) * 10_000)
    let fraction = raw - floor(raw)
    guard self <= Date(), fraction > 0.4 else { return nil }
    if mode == "expense" {
      return Int(fraction * 200) + 10
    }
    return Int(fraction * 500) + 50
  }
}
