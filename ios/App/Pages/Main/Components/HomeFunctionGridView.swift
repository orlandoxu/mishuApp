import SwiftUI

struct HomeFunctionGridView: View {
  let onSelect: (NavigationRoute) -> Void

  private let items: [HomeFunctionItem] = [
    HomeFunctionItem(title: "TA", imageName: "img_card_love", route: .partner),
    HomeFunctionItem(title: "我的朋友", imageName: "img_card_friends", route: .contacts),
    HomeFunctionItem(title: "小钱罐", imageName: "img_card_money", route: .moneyJar),
    HomeFunctionItem(title: "独家记忆", imageName: "img_card_memory", route: .trueMemory),
    HomeFunctionItem(title: "情绪树洞", imageName: "img_card_emo_girl", route: .treeHole),
    HomeFunctionItem(title: "我的画像", imageName: "img_card_self", route: .memory),
    HomeFunctionItem(title: "我的", imageName: "img_menu_self", route: .settings),
    HomeFunctionItem(title: "小宝贝", imageName: "img_card_child", route: .child)
  ]

  var body: some View {
    LazyVGrid(
      columns: Array(repeating: GridItem(.flexible(), spacing: 40), count: 3),
      spacing: 40
    ) {
      ForEach(items) { item in
        Button {
          onSelect(item.route)
        } label: {
          VStack(spacing: 9) {
            Image(item.imageName)
              .resizable()
              .scaledToFit()
              .frame(width: 44, height: 44)

            Text(item.title)
              .font(.system(size: 13, weight: .black))
              .foregroundColor(Color.black.opacity(0.80))
              .lineLimit(1)
              .minimumScaleFactor(0.82)
          }
          .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.horizontal, 24)
    .frame(maxWidth: 320)
  }
}

private struct HomeFunctionItem: Identifiable {
  let id = UUID()
  let title: String
  let imageName: String
  let route: NavigationRoute
}
