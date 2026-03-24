import SwiftUI

enum MessageTabType: Int, CaseIterable {
  case recorder = 0
  case activity = 1
  case system = 2

  var title: String {
    switch self {
    case .recorder: return "记录仪消息"
    case .activity: return "活动消息"
    case .system: return "系统消息"
    }
  }
}

struct MessageTabs: View {
  @Binding var selectedTab: MessageTabType

  private var selectedScale: CGFloat {
    22.0 / 18.0
  }

  private var tabAnimation: Animation {
    .interactiveSpring(response: 0.25, dampingFraction: 0.9)
  }

  var body: some View {
    HStack(spacing: 0) {
      ForEach(MessageTabType.allCases, id: \.self) { tab in
        Button {
          selectedTab = tab
        } label: {
          Text(tab.title)
            .font(.system(size: 18, weight: .medium))
            .scaleEffect(selectedTab == tab ? selectedScale : 1.0)
            .foregroundColor(selectedTab == tab ? Color(hex: "0x06BAFF") : Color(hex: "0x666666"))
            .animation(tabAnimation, value: selectedTab)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
        }
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 6)
    .background(Color.white)
  }
}
