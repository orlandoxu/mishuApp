import SwiftUI

struct FoodDeleteConfirmView: View {
  let onCancel: () -> Void
  let onDelete: () -> Void

  var body: some View {
    ZStack {
      Color.black.opacity(0.40).ignoresSafeArea()

      VStack(spacing: 16) {
        Text("确定要删除吗？")
          .font(.system(size: 20, weight: .black))
          .foregroundColor(Color.black.opacity(0.82))

        Text("这条美食记忆将被永久删除，此操作无法恢复。")
          .font(.system(size: 15, weight: .medium))
          .foregroundColor(Color.black.opacity(0.58))

        HStack(spacing: 10) {
          Button("取消", action: onCancel)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(hex: "#F4F5F7"))
            .foregroundColor(Color.black.opacity(0.62))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

          Button("删除", action: onDelete)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(hex: "#EF4444"))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .accessibilityIdentifier("food_memory_confirm_delete")
        }
      }
      .padding(20)
      .background(Color.white)
      .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
      .padding(.horizontal, 24)
    }
  }
}
