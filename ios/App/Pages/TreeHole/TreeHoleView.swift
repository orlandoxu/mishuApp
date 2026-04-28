import SwiftUI

struct TreeHoleView: View {
  private let moods = [
    MoodEntry(id: "1", date: "2026-04-28", emoji: "😊", content: "今天心情不错，完成了一个小功能！"),
    MoodEntry(id: "2", date: "2026-04-27", emoji: "🤔", content: "有点纠结，不知道接下来的方向。")
  ]

  var body: some View {
    ZStack(alignment: .bottom) {
      Color(hex: "#F8F9FB").ignoresSafeArea()

      VStack(spacing: 0) {
        NavHeader(title: "情绪树洞") {
          Image(systemName: "ellipsis")
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(.black.opacity(0.58))
            .frame(width: 44, height: 44)
        }

        ScrollView(showsIndicators: false) {
          VStack(spacing: 18) {
            MoodCalendarView(entries: moods)
            ForEach(moods) { mood in
              MoodEntryCard(entry: mood)
            }
          }
          .padding(.horizontal, 20)
          .padding(.top, 16)
          .padding(.bottom, 118)
        }
      }

      Button {
      } label: {
        Label("记录情绪", systemImage: "plus")
          .font(.system(size: 18, weight: .bold))
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .frame(height: 64)
          .background(Color.black)
          .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
          .shadow(color: Color.black.opacity(0.15), radius: 18, x: 0, y: 10)
      }
      .buttonStyle(.plain)
      .padding(24)
    }
  }
}
