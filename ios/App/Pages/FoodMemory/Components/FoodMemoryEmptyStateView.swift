import SwiftUI

struct FoodMemoryEmptyStateView: View {
  var body: some View {
    VStack(spacing: 14) {
      Spacer(minLength: 0)

      Image(systemName: "fork.knife")
        .font(.system(size: 58, weight: .light))
        .foregroundColor(Color.black.opacity(0.12))

      Text("快去添加你的第一条美食记忆吧")
        .font(.system(size: 40 / 2, weight: .medium))
        .foregroundColor(Color.black.opacity(0.24))

      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.bottom, 80)
    .accessibilityIdentifier("food_memory_empty_state")
  }
}
