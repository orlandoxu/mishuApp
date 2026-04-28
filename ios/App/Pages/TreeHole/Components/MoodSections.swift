import SwiftUI

struct MoodEntry: Identifiable {
  let id: String
  let date: String
  let emoji: String
  let content: String
}

struct MoodCalendarView: View {
  let entries: [MoodEntry]

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("四月心情")
        .font(.system(size: 18, weight: .black))
      LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
        ForEach(1...28, id: \.self) { day in
          ZStack {
            if day == 27 || day == 28 {
              Text(day == 27 ? "🤔" : "😊")
                .font(.system(size: 28))
            } else {
              Text("\(day)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.black.opacity(0.36))
            }
          }
          .frame(height: 44)
          .frame(maxWidth: .infinity)
          .background((day == 27 || day == 28) ? Color.black.opacity(0.04) : Color.clear)
          .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
      }
    }
    .padding(18)
    .background(Color.white.opacity(0.50))
    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
  }
}

struct MoodEntryCard: View {
  let entry: MoodEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text(entry.date).font(.system(size: 13, weight: .medium)).foregroundColor(.black.opacity(0.40))
        Spacer()
        Text(entry.emoji).font(.system(size: 30))
      }
      Text(entry.content)
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(Color.black.opacity(0.78))
        .lineSpacing(4)
    }
    .padding(20)
    .background(Color.white)
    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
  }
}
