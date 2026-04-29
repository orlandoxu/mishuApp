import SwiftUI

struct TreeHoleView: View {
  @ObservedObject private var appNavigation = AppNavigationModel.shared
  @State private var moods = [
    MoodEntry(id: "1", date: "2026-04-28", moodEmoji: "😊", content: "今天心情不错，完成了一个小功能！"),
    MoodEntry(id: "2", date: "2026-04-27", moodEmoji: "🤔", content: "有点纠结，不知道接下来的方向。")
  ]
  @State private var selectedYear: Int
  @State private var selectedMonth: Int

  init() {
    let components = Calendar.current.dateComponents([.year, .month], from: Date())
    _selectedYear = State(initialValue: components.year ?? 2026)
    _selectedMonth = State(initialValue: (components.month ?? 4) - 1)
  }

  private var monthTitle: String {
    "\(selectedYear)年\(selectedMonth + 1)月"
  }

  private var moodMap: [String: String] {
    Dictionary(uniqueKeysWithValues: moods.map { ($0.date, $0.moodEmoji) })
  }

  var body: some View {
    ZStack {
      Color(hex: "#FFFBF0").ignoresSafeArea()

      VStack(spacing: 0) {
        treeHoleHeader

        ScrollView(showsIndicators: false) {
          VStack(alignment: .leading, spacing: 30) {
            MoodCalendarView(
              moodMap: moodMap,
              year: selectedYear,
              month: selectedMonth
            ) { year, month in
              selectedYear = year
              selectedMonth = month
            }
            .padding(.top, 3)

            VStack(alignment: .leading, spacing: 20) {
              Image("img_emo_subtitle")
                .resizable()
                .scaledToFit()
                .frame(width: 144, height: 40, alignment: .leading)

              VStack(spacing: 16) {
                ForEach(moods) { mood in
                  MoodEntryCard(entry: mood) {
                    withAnimation(.easeOut(duration: 0.2)) {
                      moods.removeAll { $0.id == mood.id }
                    }
                  } onChat: {
                    appNavigation.push(.treeHoleChat(initialMoodContent: mood.content))
                  }
                }
              }
            }
          }
          .padding(.horizontal, 24)
          .padding(.bottom, 36)
        }
      }
    }
    .navigationBarHidden(true)
  }

  private var treeHoleHeader: some View {
    NavHeader(title: "") {
      Image(systemName: "ellipsis")
        .font(.system(size: 20, weight: .bold))
        .foregroundColor(Color.black.opacity(0.58))
    }
    .overlay(alignment: .center) {
      Text(monthTitle)
        .font(.system(size: 20, weight: .black))
        .foregroundColor(Color.black.opacity(0.80))
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(
          UnevenRoundedBlob()
            .fill(Color.yellow.opacity(0.36))
            .blur(radius: 2)
            .rotationEffect(.degrees(3))
        )
        .allowsHitTesting(false)
    }
  }
}

private struct UnevenRoundedBlob: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.minY + rect.height * 0.32))
    path.addCurve(
      to: CGPoint(x: rect.minX + rect.width * 0.55, y: rect.minY + rect.height * 0.04),
      control1: CGPoint(x: rect.minX + rect.width * 0.20, y: rect.minY + rect.height * 0.02),
      control2: CGPoint(x: rect.minX + rect.width * 0.40, y: rect.minY - rect.height * 0.02)
    )
    path.addCurve(
      to: CGPoint(x: rect.maxX - rect.width * 0.06, y: rect.minY + rect.height * 0.30),
      control1: CGPoint(x: rect.minX + rect.width * 0.76, y: rect.minY + rect.height * 0.09),
      control2: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.04)
    )
    path.addCurve(
      to: CGPoint(x: rect.maxX - rect.width * 0.18, y: rect.maxY - rect.height * 0.12),
      control1: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.54),
      control2: CGPoint(x: rect.maxX - rect.width * 0.01, y: rect.maxY - rect.height * 0.22)
    )
    path.addCurve(
      to: CGPoint(x: rect.minX + rect.width * 0.26, y: rect.maxY - rect.height * 0.06),
      control1: CGPoint(x: rect.maxX - rect.width * 0.34, y: rect.maxY + rect.height * 0.03),
      control2: CGPoint(x: rect.minX + rect.width * 0.48, y: rect.maxY)
    )
    path.addCurve(
      to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.minY + rect.height * 0.32),
      control1: CGPoint(x: rect.minX + rect.width * 0.06, y: rect.maxY - rect.height * 0.12),
      control2: CGPoint(x: rect.minX + rect.width * 0.02, y: rect.minY + rect.height * 0.55)
    )
    path.closeSubpath()
    return path
  }
}
