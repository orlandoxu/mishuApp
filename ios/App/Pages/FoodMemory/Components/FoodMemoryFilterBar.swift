import SwiftUI

enum FoodMemoryViewMode {
  case list
  case map
}

struct FoodMemoryFilterBar: View {
  let categories: [String]
  let selectedCategory: String
  let viewMode: FoodMemoryViewMode
  let onToggleMap: () -> Void
  let onSelectCategory: (String) -> Void

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        Button(action: onToggleMap) {
          HStack(spacing: 4) {
            Image(systemName: "map")
              .font(.system(size: 13, weight: .bold))
            Text("地图")
              .font(.system(size: 13, weight: .bold))
          }
          .padding(.horizontal, 14)
          .padding(.vertical, 8)
          .background(viewMode == .map ? Color.white : Color.white.opacity(0.52))
          .foregroundColor(viewMode == .map ? Color.black.opacity(0.82) : Color.black.opacity(0.55))
          .clipShape(Capsule())
          .shadow(color: Color.black.opacity(viewMode == .map ? 0.05 : 0), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("food_memory_toggle_map")

        ForEach(categories, id: \.self) { category in
          Button {
            onSelectCategory(category)
          } label: {
            Text(category)
              .font(.system(size: 13, weight: .bold))
              .padding(.horizontal, 14)
              .padding(.vertical, 8)
              .background(selectedCategory == category ? Color(hex: "#FF6B6B") : Color.white.opacity(0.52))
              .foregroundColor(selectedCategory == category ? .white : Color.black.opacity(0.55))
              .clipShape(Capsule())
              .shadow(color: Color(hex: "#FF6B6B").opacity(selectedCategory == category ? 0.20 : 0), radius: 12, x: 0, y: 4)
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier("food_memory_category_\(category)")
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 10)
    }
  }
}
