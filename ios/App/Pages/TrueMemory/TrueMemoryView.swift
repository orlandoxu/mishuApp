import SwiftUI

struct TrueMemoryView: View {
  @State private var selectedCategory: String? = nil
  @State private var query = ""
  @State private var searchExpanded = false
  @FocusState private var isSearchFocused: Bool

  private let topOverlayHeight: CGFloat = 204
  private var timelineTopPadding: CGFloat {
    topOverlayHeight + TrueMemoryTimelineCard.topIconOverhang
  }

  private let memories = [
    TrueMemoryItem(id: "m1", text: "我的车牌号是 粤B·12345，平时停在负二层 B2-105", time: "2026-04-15 14:30", category: "个人信息"),
    TrueMemoryItem(id: "m2", text: "帮我记住，家里大门的智能锁密码换成 886622 了，千万别忘", time: "2026-04-10 09:15", category: "安全备忘"),
    TrueMemoryItem(id: "m3", text: "今年年底带全家去北海道看雪，预算大概在 5 万以内，记得提醒我提前订机票", time: "2026-03-22 21:00", category: "旅行计划"),
    TrueMemoryItem(id: "m4", text: "下次和 Sarah 开会，一定要跟她 review 一下上个季度的增长数据", time: "2026-03-18 11:20", category: "工作事项"),
    TrueMemoryItem(id: "m5", text: "老婆对芒果重度过敏，以后定外卖绝对不能点任何带有芒果的饮品或甜点", time: "2026-02-14 19:05", category: "家庭备忘")
  ]

  private var filteredMemories: [TrueMemoryItem] {
    memories.filter { item in
      let categoryMatch = selectedCategory == nil || item.category == selectedCategory
      let queryMatch = query.isEmpty || item.text.localizedCaseInsensitiveContains(query) || item.category.localizedCaseInsensitiveContains(query)
      return categoryMatch && queryMatch
    }
  }

  var body: some View {
    GeometryReader { proxy in
      ZStack(alignment: .top) {
        pageBackground(size: proxy.size)
          .ignoresSafeArea()

        ScrollView(showsIndicators: false) {
          ZStack(alignment: .topLeading) {
            Rectangle()
              .fill(Color.black.opacity(0.04))
              .frame(width: 1)
              .padding(.leading, 8)
              .padding(.top, 16)
              .padding(.bottom, 4)

            VStack(spacing: 32) {
              ForEach(filteredMemories) { item in
                TrueMemoryTimelineCard(item: item)
                  .frame(maxWidth: .infinity, alignment: .leading)
              }
            }
          }
          .padding(.horizontal, 24)
          .padding(.top, timelineTopPadding)
          .padding(.bottom, 40)
        }
        .frame(width: proxy.size.width, height: proxy.size.height)
        .scrollDismissesKeyboard(.interactively)

        pageBackground(size: proxy.size)
          .frame(width: proxy.size.width, height: topOverlayHeight, alignment: .top)
          .clipped()
          .allowsHitTesting(false)
          .zIndex(9)

        topOverlay
          .frame(width: proxy.size.width)
          .zIndex(10)
      }
      .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
    }
    .ignoresSafeArea(.keyboard, edges: .bottom)
    .ignoresSafeArea()
  }

  private func pageBackground(size: CGSize) -> some View {
    ZStack {
      Color(hex: "#F8F9FB")
      Image("img_bg_memory")
        .resizable()
        .scaledToFill()
        .frame(width: size.width, height: size.height, alignment: .top)
        .opacity(0.40)
        .clipped()
    }
  }

  private var topOverlay: some View {
    VStack(spacing: 0) {
      header
      categories
    }
    .allowsHitTesting(true)
  }

  private var header: some View {
    HStack(spacing: 14) {
      if !searchExpanded {
        HStack(spacing: 14) {
          Button {
            AppNavigationModel.shared.pop()
          } label: {
            Image(systemName: "arrow.left")
              .font(.system(size: 24, weight: .semibold))
              .foregroundColor(Color.black.opacity(0.82))
          }
          .frame(width: 48, height: 48)
          .background(Color.white.opacity(0.30))
          .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
          .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
              .stroke(Color.white.opacity(0.60), lineWidth: 1)
          )
          .buttonStyle(.plain)

          Text("独家记忆")
            .font(.system(size: 20, weight: .black))
            .foregroundColor(Color.black.opacity(0.80))
            .frame(maxWidth: .infinity)
        }
        .transition(.opacity.combined(with: .move(edge: .leading)))
      }

      HStack(spacing: searchExpanded ? 8 : 0) {
        if searchExpanded {
          Image(systemName: "magnifyingglass")
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(Color.black.opacity(0.40))
          TextField("搜索记忆过的事项", text: $query)
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(Color.black.opacity(0.80))
            .focused($isSearchFocused)
          Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
              searchExpanded = false
              query = ""
              isSearchFocused = false
            }
          } label: {
            Image(systemName: "xmark")
              .font(.system(size: 14, weight: .bold))
              .foregroundColor(Color.black.opacity(0.30))
          }
          .buttonStyle(.plain)
          .transition(.scale.combined(with: .opacity))
        } else {
          Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
              searchExpanded = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
              isSearchFocused = true
            }
          } label: {
            Image(systemName: "magnifyingglass")
              .font(.system(size: 22, weight: .semibold))
              .foregroundColor(Color.black.opacity(0.60))
          }
          .buttonStyle(.plain)
        }
      }
      .padding(.horizontal, searchExpanded ? 16 : 0)
      .frame(maxWidth: searchExpanded ? .infinity : 48, alignment: .center)
      .frame(height: 48)
      .background(Color.white.opacity(0.30))
      .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 24, style: .continuous)
          .stroke(Color.white.opacity(0.60), lineWidth: 1)
      )
      .shadow(color: Color.black.opacity(0.03), radius: 32, x: 0, y: 8)
    }
    .padding(.horizontal, 24)
    .padding(.top, 56)
    .padding(.bottom, 16)
    .frame(minHeight: 110)
    .animation(.spring(response: 0.35, dampingFraction: 0.84), value: searchExpanded)
    .ignoresSafeArea(.keyboard, edges: .bottom)
  }

  private var categories: some View {
    Group {
      if #available(iOS 17.0, *) {
        categoryScroll.scrollClipDisabled(true)
      } else {
        categoryScroll
      }
    }
    .padding(.bottom, 2)
  }

  private var categoryScroll: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 10) {
        TrueMemoryCategoryButton(title: "全部", imageName: nil, isSelected: selectedCategory == nil) {
          selectedCategory = nil
        }
        TrueMemoryCategoryButton(title: "个人信息", imageName: "img_memory_robot", isSelected: selectedCategory == "个人信息") {
          selectedCategory = "个人信息"
        }
        TrueMemoryCategoryButton(title: "安全备忘", imageName: "img_memory_memo", isSelected: selectedCategory == "安全备忘") {
          selectedCategory = "安全备忘"
        }
        TrueMemoryCategoryButton(title: "旅行计划", imageName: "img_memory_travel", isSelected: selectedCategory == "旅行计划") {
          selectedCategory = "旅行计划"
        }
      }
      .padding(.horizontal, 24)
      .padding(.vertical, 16)
    }
  }
}
