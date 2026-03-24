import SwiftUI

enum MainTab: Hashable {
  case recorder
  case message
  case mine
}

struct MainTabView: View {
  @State private var selectedTab: MainTab = .recorder
  @State private var safeAreaInsets: EdgeInsets = .init()

  init(initialTab: MainTab) {
    _selectedTab = State(initialValue: initialTab)
  }

  var body: some View {
    ZStack(alignment: .bottom) {
      Group {
        switch selectedTab {
        case .recorder:
          VehicleListView()
        case .message:
          MessageView()
        case .mine:
          MeView()
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)

      CustomTabBar(selectedTab: $selectedTab, bottomInset: safeAreaInsets.bottom)
    }
    .captureSafeAreaInsets { insets in
      safeAreaInsets = insets
    }
    .background(Color.white.ignoresSafeArea())
  }
}

private struct CustomTabBar: View {
  @Binding var selectedTab: MainTab
  @ObservedObject private var messageStore: MessageStore = .shared
  let bottomInset: CGFloat
  private let activeColor = Color(red: 0x06 / 255.0, green: 0xBA / 255.0, blue: 0xFF / 255.0)
  private let inactiveColor = Color(red: 0x94 / 255.0, green: 0xA3 / 255.0, blue: 0xB8 / 255.0)

  private var hasUnreadMessages: Bool {
    messageStore.allMessages.contains { $0.status == 1 }
  }

  var body: some View {
    VStack(spacing: 0) {
      Rectangle()
        .fill(Color.black.opacity(0.06))
        .frame(height: 1)
      HStack(spacing: 0) {
        tabButton(title: "记录仪", iconName: "tab_camera", iconActiveName: "tab_camera_active", tab: .recorder)
        tabButton(
          title: "消息",
          iconName: "tab_message",
          iconActiveName: "tab_message_active",
          tab: .message,
          showUnreadBadge: hasUnreadMessages
        )
        tabButton(title: "我的", iconName: "tab_me", iconActiveName: "tab_me_active", tab: .mine)
      }
      .frame(height: 56)
      .background(Color.white)
    }
    .padding(.bottom, bottomInset)
    .background(Color.white.ignoresSafeArea(edges: .bottom))
  }

  private func tabButton(
    title: String,
    iconName: String,
    iconActiveName: String,
    tab: MainTab,
    showUnreadBadge: Bool = false
  ) -> some View {
    let isActive = selectedTab == tab
    return Button {
      selectedTab = tab
    } label: {
      VStack(spacing: 4) {
        ZStack(alignment: .topTrailing) {
          Image(isActive ? iconActiveName : iconName)
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 24, height: 24)

          if showUnreadBadge {
            Circle()
              .fill(Color.red)
              .frame(width: 9, height: 9)
              .overlay(
                Circle()
                  .stroke(Color.white, lineWidth: 1.5)
              )
              .offset(x: 2, y: -1)
          }
        }
        .frame(width: 24, height: 24)

        Text(title)
          .font(.system(size: 10, weight: .medium))
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .foregroundColor(isActive ? activeColor : inactiveColor)
    }
    .buttonStyle(.plain)
  }
}

private struct SafeAreaInsetsPreferenceKey: PreferenceKey {
  static var defaultValue: EdgeInsets = .init()

  static func reduce(value: inout EdgeInsets, nextValue: () -> EdgeInsets) {
    value = nextValue()
  }
}

private extension View {
  func captureSafeAreaInsets(_ onChange: @escaping (EdgeInsets) -> Void) -> some View {
    background(
      GeometryReader { proxy in
        Color.clear
          .preference(
            key: SafeAreaInsetsPreferenceKey.self,
            value: EdgeInsets(
              top: proxy.safeAreaInsets.top,
              leading: proxy.safeAreaInsets.leading,
              bottom: proxy.safeAreaInsets.bottom,
              trailing: proxy.safeAreaInsets.trailing
            )
          )
      }
    )
    .onPreferenceChange(SafeAreaInsetsPreferenceKey.self, perform: onChange)
  }
}
