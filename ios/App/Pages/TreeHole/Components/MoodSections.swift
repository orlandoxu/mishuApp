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

  @State private var dragOffset: CGFloat = 0

  private var daysInMonth: Int {
    var components = DateComponents()
    components.year = year
    components.month = month + 1
    guard let date = Calendar.current.date(from: components),
          let range = Calendar.current.range(of: .day, in: .month, for: date)
    else {
      return 30
    }
    return range.count
  }

  var body: some View {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 7), spacing: 12) {
      ForEach(1...daysInMonth, id: \.self) { day in
        calendarDay(day)
      }
    }
    .offset(x: dragOffset)
    .animation(.easeOut(duration: 0.24), value: dragOffset)
    .gesture(
      DragGesture(minimumDistance: 20)
        .onChanged { value in
          dragOffset = max(-36, min(36, value.translation.width * 0.25))
        }
        .onEnded { value in
          let projected = value.predictedEndTranslation.width
          if value.translation.width < -50 || projected < -120 {
            changeMonth(by: 1)
          } else if value.translation.width > 50 || projected > 120 {
            changeMonth(by: -1)
          }
          dragOffset = 0
        }
    )
  }

  @ViewBuilder
  private func calendarDay(_ day: Int) -> some View {
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

  private func changeMonth(by delta: Int) {
    var components = DateComponents()
    components.year = year
    components.month = month + 1 + delta
    components.day = 1
    guard let date = Calendar.current.date(from: components) else { return }
    let next = Calendar.current.dateComponents([.year, .month], from: date)
    guard let nextYear = next.year, let nextMonth = next.month else { return }
    onMonthChange(nextYear, nextMonth - 1)
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
