import SwiftUI

struct ProMembershipView: View {
  @State private var selectedPlanId = "lifetime"
  @ObservedObject private var navigation = AppNavigationModel.shared

  private let plans = [
    ProPlan(id: "monthly", name: "月度会员", price: "¥18", period: "1个月", isPopular: false),
    ProPlan(id: "lifetime", name: "终生版", price: "¥198", period: "永久", isPopular: true),
    ProPlan(id: "yearly", name: "年度会员", price: "¥168", period: "1年", isPopular: false)
  ]

  private var selectedPlan: ProPlan {
    plans.first { $0.id == selectedPlanId } ?? plans[1]
  }

  var body: some View {
    ZStack(alignment: .bottom) {
      LinearGradient(
        colors: [Color(hex: "#F1E8FF"), Color(hex: "#F8F9FB")],
        startPoint: .top,
        endPoint: .center
      )
      .ignoresSafeArea()

      VStack(spacing: 0) {
        NavHeader(title: "会员中心")
        ScrollView(showsIndicators: false) {
          VStack(spacing: 26) {
            HStack(spacing: 10) {
              ForEach(plans) { plan in
                ProPlanButton(plan: plan, isSelected: selectedPlanId == plan.id) {
                  selectedPlanId = plan.id
                }
              }
            }

            VStack(alignment: .leading, spacing: 12) {
              Text("PRO 专属权益")
                .font(.system(size: 13, weight: .black))
                .foregroundColor(.black.opacity(0.30))
                .padding(.leading, 4)
              ProFeatureRow(symbol: "sparkles", color: Color(hex: "#EAB308"), title: "更聪明的大脑", desc: "可设置更高的大脑模型")
              ProFeatureRow(symbol: "clock.arrow.circlepath", color: Color(hex: "#3B82F6"), title: "可恢复归档的数据", desc: "可找回归档了的记忆")
              ProFeatureRow(symbol: "lock.shield.fill", color: Color(hex: "#10B981"), title: "云端加密备份", desc: "本地数据可加密后云端备份")
              ProFeatureRow(symbol: "lock.open.fill", color: Color(hex: "#8B5CF6"), title: "解锁锁定功能", desc: "获得所有专属助手模块完整访问")
            }
          }
          .padding(.horizontal, 20)
          .padding(.top, 22)
          .padding(.bottom, 132)
        }
      }

      VStack(spacing: 12) {
        Text("订阅即代表您同意会员协议与隐私政策。")
          .font(.system(size: 11, weight: .medium))
          .foregroundColor(.black.opacity(0.30))
        Button {
          navigation.push(.checkout(planName: selectedPlan.name, price: selectedPlan.price))
        } label: {
          HStack(spacing: 6) {
            Text("立即开通 Pro")
            Image(systemName: "chevron.right")
          }
          .font(.system(size: 17, weight: .black))
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .frame(height: 56)
          .background(LinearGradient(colors: [Color(hex: "#8B5CF6"), Color(hex: "#F472B6")], startPoint: .leading, endPoint: .trailing))
          .clipShape(Capsule())
        }
        .buttonStyle(.plain)
      }
      .padding(24)
      .background(
        LinearGradient(colors: [Color(hex: "#F8F9FB"), Color(hex: "#F8F9FB").opacity(0)], startPoint: .bottom, endPoint: .top)
      )
    }
  }
}
