import SwiftUI

struct TrueMemoryView: View {
  @State private var selectedCategory: String? = nil
  @State private var query = ""
  @State private var searchExpanded = false

  private let memories = [
    TrueMemoryItem(id: "m1", text: "我的车牌号是 粤B·12345，平时停在负二层 B2-105", time: "2026-04-15 14:30", category: "个人信息"),
    TrueMemoryItem(id: "m2", text: "家里大门的智能锁密码换成 886622 了，千万别忘", time: "2026-04-10 09:15", category: "安全备忘"),
    TrueMemoryItem(id: "m3", text: "今年年底带全家去北海道看雪，预算大概在 5 万以内", time: "2026-03-22 21:00", category: "旅行计划"),
    TrueMemoryItem(id: "m4", text: "下次和 Sarah 开会，要 review 上个季度的增长数据", time: "2026-03-18 11:20", category: "工作事项")
  ]

  private var filteredMemories: [TrueMemoryItem] {
    memories.filter { item in
      let categoryMatch = selectedCategory == nil || item.category == selectedCategory
      let queryMatch = query.isEmpty || item.text.localizedCaseInsensitiveContains(query) || item.category.localizedCaseInsensitiveContains(query)
      return categoryMatch && queryMatch
    }
  }

  var body: some View {
    ZStack(alignment: .top) {
      Color(hex: "#F8F9FB").ignoresSafeArea()
      Image("img_bg_memory")
        .resizable()
        .scaledToFill()
        .opacity(0.40)
        .ignoresSafeArea()

      VStack(spacing: 0) {
        header
        categories

        ScrollView(showsIndicators: false) {
          VStack(spacing: 0) {
            ForEach(filteredMemories) { item in
              TrueMemoryTimelineCard(item: item)
            }
          }
          .padding(.horizontal, 22)
          .padding(.top, 24)
          .padding(.bottom, 38)
        }
      }
    }
  }

  private var header: some View {
    HStack(spacing: 12) {
      if !searchExpanded {
        NavHeader(title: "独家记忆")
      } else {
        HStack(spacing: 8) {
          Image(systemName: "magnifyingglass")
            .foregroundColor(Color.black.opacity(0.40))
          TextField("搜索记忆过的事项", text: $query)
            .font(.system(size: 15, weight: .bold))
          Button {
            searchExpanded = false
            query = ""
          } label: {
            Image(systemName: "xmark")
              .foregroundColor(Color.black.opacity(0.30))
          }
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(Color.white.opacity(0.42))
        .clipShape(Capsule())
        .padding(.top, safeAreaTop + 14)
        .padding(.horizontal, 20)
      }

      if !searchExpanded {
        Button {
          searchExpanded = true
        } label: {
          Image(systemName: "magnifyingglass")
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(Color.black.opacity(0.60))
            .frame(width: 48, height: 48)
            .background(Color.white.opacity(0.45))
            .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .padding(.top, safeAreaTop + 13)
        .padding(.trailing, 20)
      }
    }
  }

  private var categories: some View {
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
      .padding(.horizontal, 22)
      .padding(.vertical, 14)
    }
  }
}
