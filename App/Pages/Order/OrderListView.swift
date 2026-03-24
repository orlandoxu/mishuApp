import SwiftUI

struct OrderListView: View {
  @StateObject private var viewModel = OrderListViewModel()
  @State private var selfStore = SelfStore.shared
  @State private var selectedPage = OrderTab.all.rawValue

  var body: some View {
    VStack(spacing: 0) {
      // Spacer().frame(height: safeAreaTop).background(Color.white)
      NavHeader(title: "我的订单")

      tabsView
      contentView
    }
    .ignoresSafeArea()
    .background(Color.white.ignoresSafeArea())
    .onAppear {
      selectedPage = viewModel.selectedTab.rawValue
      Task {
        await viewModel.loadOrders()
      }
    }
  }

  private var safeAreaTop: CGFloat {
    UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0
  }

  private var tabsView: some View {
    HStack(spacing: 0) {
      ForEach(OrderTab.allCases) { tab in
        tabButton(for: tab)
      }
    }
    .background(Color.white)
  }

  private func tabButton(for tab: OrderTab) -> some View {
    Button {
      withAnimation {
        selectedPage = tab.rawValue
      }
    } label: {
      VStack(spacing: 6) {
        Text(tab.title)
          .font(.system(size: 15, weight: isSelected(tab) ? .medium : .regular))
          .foregroundColor(isSelected(tab) ? Color(hex: "0x06BAFF") : Color(hex: "0x666666"))

        Rectangle()
          .fill(isSelected(tab) ? Color(hex: "0x06BAFF") : Color.clear)
          .frame(width: 20, height: 2)
          .cornerRadius(1)
      }
      .frame(maxWidth: .infinity)
      .frame(height: 44)
    }
    .buttonStyle(.plain)
    .contentShape(Rectangle())
    .frame(maxWidth: .infinity)
    .frame(height: 44)
  }

  private var contentView: some View {
    TabView(selection: $selectedPage) {
      ForEach(OrderTab.allCases) { tab in
        // 通过让 TabView / Page 填满剩余高度，修复列表高度过低与滚动显示异常
        OrderListPage(orders: viewModel.orders(for: tab))
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
          .tag(tab.rawValue)
      }
    }
    .tabViewStyle(.page(indexDisplayMode: .never))
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .padding(.horizontal, 20)
    .background(Color(hex: "0xF8F9FA"))
    .onChange(of: selectedPage) { newValue in
      if let tab = OrderTab(rawValue: newValue), viewModel.selectedTab != tab {
        viewModel.selectedTab = tab
      }
    }
  }

  private func isSelected(_ tab: OrderTab) -> Bool {
    selectedPage == tab.rawValue
  }
}

// DONE-AI: 页面组件已拆分到 Pages/Order/Components
