import SwiftUI

struct MoodEntry: Identifiable, Equatable {
  let id: String
  let date: String
  let moodEmoji: String
  let content: String

  var iconName: String {
    MoodIcon.name(for: moodEmoji)
  }

  var dottedDate: String {
    date.replacingOccurrences(of: "-", with: ".")
  }

  var actionTitle: String {
    ["☹️", "😞"].contains(moodEmoji) ? "和解" : "遗忘"
  }

  var empathyPrompt: String {
    switch id {
    case "1":
      return "你一定不知所措，要不要一起理一理这件事情？"
    case "2":
      return "我在这里陪着你，愿意和我说说发生了什么吗？"
    default:
      return "这种感觉很辛苦吧，想不想找个人聊聊？"
    }
  }
}

enum MoodIcon {
  static func name(for emoji: String) -> String {
    switch emoji {
    case "😊":
      return "icon_emo_kaixin"
    case "🤔":
      return "icon_emo_jiaolv"
    case "☹️":
      return "icon_emo_beishang"
    case "😞":
      return "icon_emo_pibei"
    case "😠":
      return "icon_emo_shengqi"
    default:
      return "icon_emo_kaixin"
    }
  }
}

struct MoodCalendarView: View {
  let moodMap: [String: String]
  let year: Int
  let month: Int
  let onMonthChange: (Int, Int) -> Void

  @State private var pageIndex: Int

  private let monthRange = -120...120
  private let calendar = Calendar.current

  init(moodMap: [String: String], year: Int, month: Int, onMonthChange: @escaping (Int, Int) -> Void) {
    self.moodMap = moodMap
    self.year = year
    self.month = month
    self.onMonthChange = onMonthChange
    _pageIndex = State(initialValue: Self.monthIndex(year: year, month: month))
  }

  private var currentPageIndex: Int {
    Self.monthIndex(year: year, month: month)
  }

  var body: some View {
    TabView(selection: $pageIndex) {
      ForEach(Array(monthRange), id: \.self) { offset in
        let index = currentPageIndex + offset
        calendarPage(for: index)
          .tag(index)
          .padding(.horizontal, 1)
      }
    }
    .tabViewStyle(.page(indexDisplayMode: .never))
    .frame(height: 260)
    .onChange(of: pageIndex) { newValue in
      let components = Self.monthComponents(from: newValue)
      guard components.year != year || components.month != month else { return }
      onMonthChange(components.year, components.month)
    }
    .onChange(of: currentPageIndex) { newValue in
      guard pageIndex != newValue else { return }
      pageIndex = newValue
    }
  }

  private func calendarPage(for index: Int) -> some View {
    let components = Self.monthComponents(from: index)
    let days = daysInMonth(year: components.year, month: components.month)

    return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 7), spacing: 12) {
      ForEach(1...days, id: \.self) { day in
        calendarDay(day, year: components.year, month: components.month)
      }
    }
    .frame(maxHeight: .infinity, alignment: .top)
  }

  private func daysInMonth(year: Int, month: Int) -> Int {
    var components = DateComponents()
    components.year = year
    components.month = month + 1
    guard let date = calendar.date(from: components),
          let range = calendar.range(of: .day, in: .month, for: date)
    else {
      return 30
    }
    return range.count
  }

  @ViewBuilder
  private func calendarDay(_ day: Int, year: Int, month: Int) -> some View {
    let dateKey = String(format: "%04d-%02d-%02d", year, month + 1, day)
    if let emoji = moodMap[dateKey] {
      Image(MoodIcon.name(for: emoji))
        .resizable()
        .scaledToFit()
        .frame(width: 40, height: 40)
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
    } else {
      Text("\(day)")
        .font(.system(size: 16, weight: .bold))
        .foregroundColor(Color.black.opacity(0.30))
        .lineLimit(1)
        .minimumScaleFactor(0.50)
        .allowsTightening(true)
        .frame(minWidth: 32, minHeight: 32)
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
    }
  }

  private static func monthIndex(year: Int, month: Int) -> Int {
    year * 12 + month
  }

  private static func monthComponents(from index: Int) -> (year: Int, month: Int) {
    let year = Int(floor(Double(index) / 12.0))
    let month = index - year * 12
    return (year, month)
  }
}

struct MoodEntryCard: View {
  let entry: MoodEntry
  let onDelete: () -> Void
  let onChat: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 13) {
      HStack(alignment: .center, spacing: 10) {
        Image(entry.iconName)
          .resizable()
          .scaledToFit()
          .frame(width: 32, height: 32)

        Text(entry.dottedDate)
          .font(.system(size: 13, weight: .bold))
          .foregroundColor(Color(hex: "#7B9260"))

        Spacer(minLength: 8)

        Button(action: onDelete) {
          HStack(spacing: 4) {
            Image(systemName: "trash")
              .font(.system(size: 13, weight: .bold))
            Text(entry.actionTitle)
              .font(.system(size: 12, weight: .bold))
          }
          .foregroundColor(Color(hex: "#A89886"))
        }
        .buttonStyle(.plain)
      }

      Text(entry.content)
        .font(.system(size: 15, weight: .medium))
        .foregroundColor(Color(hex: "#5D5750"))
        .lineSpacing(5)
        .fixedSize(horizontal: false, vertical: true)

      Button(action: onChat) {
        Text(entry.empathyPrompt)
          .font(.system(size: 13, weight: .medium))
          .foregroundColor(Color(hex: "#A89886"))
          .underline()
          .multilineTextAlignment(.leading)
          .fixedSize(horizontal: false, vertical: true)
      }
      .buttonStyle(.plain)
      .padding(.top, 1)
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .frame(minHeight: 118)
    .background(Color.white)
    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
  }
}
