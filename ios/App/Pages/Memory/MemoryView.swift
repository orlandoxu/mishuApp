import SwiftUI

struct MemoryView: View {
  private let clusters = [
    MemoryCluster(title: "餐饮偏好", symbol: "cup.and.saucer.fill", color: Color(hex: "#F97316"), items: ["不喜欢吃香菜", "重度清咖（每天 9 点）", "对海鲜轻度过敏"]),
    MemoryCluster(title: "出行习惯", symbol: "mappin.and.ellipse", color: Color(hex: "#3B82F6"), items: ["首选专车服务", "周五常去南山商圈"]),
    MemoryCluster(title: "作息规律", symbol: "clock.fill", color: Color(hex: "#8B5CF6"), items: ["晚上 11:30 深度睡眠", "周末自然醒无闹钟"])
  ]

  var body: some View {
    ZStack(alignment: .top) {
      LinearGradient(
        colors: [Color(hex: "#E8F2FF"), Color(hex: "#F8F9FB")],
        startPoint: .top,
        endPoint: .center
      )
      .ignoresSafeArea()

      VStack(spacing: 0) {
        NavHeader(title: "个人画像") {
          Image(systemName: "sparkles")
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(Color(hex: "#12B7F5"))
            .frame(width: 44, height: 44)
            .background(Color.white.opacity(0.45))
            .clipShape(Circle())
        }

        ScrollView(showsIndicators: false) {
          VStack(spacing: 22) {
            VStack(alignment: .leading, spacing: 10) {
              Text("Aura 懂你所需")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(hex: "#12B7F5"))
              Text("这里沉淀了 Aura 在日常交互中为你自动提取的高阶偏好和习惯洞察，只为提供更加无感的专属服务体验。")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.black.opacity(0.60))
                .lineSpacing(5)
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.38))
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

            ForEach(clusters) { cluster in
              MemoryClusterCard(cluster: cluster)
            }
          }
          .padding(.horizontal, 20)
          .padding(.top, 18)
          .padding(.bottom, 40)
        }
      }
    }
  }
}
