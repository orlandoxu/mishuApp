import SwiftUI

struct HomeFunctionGridView: View {
  let onSelect: (NavigationRoute) -> Void

  private let items: [HomeFunctionItem] = [
    HomeFunctionItem(title: "我的朋友", symbol: "person.2.fill", colors: ["#B9E7FF", "#6EA8FF"], route: .contacts),
    HomeFunctionItem(title: "TA", symbol: "heart.fill", colors: ["#FFD1DC", "#FF7AA2"], route: .partner),
    HomeFunctionItem(title: "独家记忆", symbol: "brain.head.profile", colors: ["#E2D7FF", "#9B7CFF"], route: .trueMemory),
    HomeFunctionItem(title: "小宝贝", symbol: "figure.and.child.holdinghands", colors: ["#FFE7B8", "#FFB84D"], route: .child),
    HomeFunctionItem(title: "小钱罐", symbol: "creditcard.fill", colors: ["#D7F8E8", "#44C986"], route: .moneyJar),
    HomeFunctionItem(title: "情绪树洞", symbol: "leaf.fill", colors: ["#D6F3F0", "#48BDB3"], route: .treeHole),
    HomeFunctionItem(title: "我的画像", symbol: "person.text.rectangle.fill", colors: ["#EAF0FF", "#7192F4"], route: .memory),
    HomeFunctionItem(title: "我的", symbol: "gearshape.fill", colors: ["#EFEFEF", "#A8ADB7"], route: .settings)
  ]

  var body: some View {
    LazyVGrid(
      columns: Array(repeating: GridItem(.flexible(), spacing: 24), count: 3),
      spacing: 26
    ) {
      ForEach(items) { item in
        Button {
          onSelect(item.route)
        } label: {
          VStack(spacing: 9) {
            ZStack {
              RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                  LinearGradient(
                    colors: item.colors.map(Color.init(hex:)),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                  )
                )
                .frame(width: 64, height: 64)
                .shadow(color: item.colors.last.map(Color.init(hex:))?.opacity(0.18) ?? .clear, radius: 14, x: 0, y: 8)

              Image(systemName: item.symbol)
                .font(.system(size: 25, weight: .bold))
                .foregroundColor(.white)
            }

            Text(item.title)
              .font(.system(size: 13, weight: .bold))
              .foregroundColor(Color.black.opacity(0.68))
              .lineLimit(1)
              .minimumScaleFactor(0.82)
          }
          .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.horizontal, 28)
  }
}

private struct HomeFunctionItem: Identifiable {
  let id = UUID()
  let title: String
  let symbol: String
  let colors: [String]
  let route: NavigationRoute
}
