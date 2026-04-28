import SwiftUI

struct PartnerIdentitySection: View {
  var body: some View {
    VStack(spacing: 16) {
      ZStack {
        Circle()
          .fill(LinearGradient(colors: [Color(hex: "#FFD1DC"), Color(hex: "#FF7AA2")], startPoint: .topLeading, endPoint: .bottomTrailing))
          .frame(width: 112, height: 112)
        Text("TA")
          .font(.system(size: 30, weight: .black))
          .foregroundColor(.white)
      }

      VStack(spacing: 6) {
        Text("亲密关系档案")
          .font(.system(size: 28, weight: .black))
          .foregroundColor(Color.black.opacity(0.86))
        Text("Aura 正在把共同生活里的细节整理成可回看的故事")
          .font(.system(size: 14, weight: .medium))
          .foregroundColor(Color.black.opacity(0.45))
          .multilineTextAlignment(.center)
      }

      HStack(spacing: 10) {
        PartnerMetric(title: "纪念日", value: "3")
        PartnerMetric(title: "偏好", value: "18")
        PartnerMetric(title: "故事", value: "42")
      }
    }
    .padding(22)
    .frame(maxWidth: .infinity)
    .background(Color.white)
    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
  }
}

private struct PartnerMetric: View {
  let title: String
  let value: String

  var body: some View {
    VStack(spacing: 4) {
      Text(value).font(.system(size: 20, weight: .black))
      Text(title).font(.system(size: 12, weight: .bold)).foregroundColor(.black.opacity(0.42))
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 12)
    .background(Color.black.opacity(0.035))
    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
  }
}

struct PartnerTimelineSection: View {
  private let stories = [
    ("第一次旅行", "在海边拍下了第一张合照，Aura 记录了她喜欢日落前二十分钟的光。"),
    ("重要提醒", "她这周工作压力偏高，适合安排一次低社交密度的晚餐。"),
    ("礼物线索", "最近反复提到木质香和小众陶瓷杯。")
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("故事时间线")
        .font(.system(size: 18, weight: .black))
        .foregroundColor(.black.opacity(0.80))

      ForEach(stories, id: \.0) { story in
        HStack(alignment: .top, spacing: 12) {
          Circle()
            .fill(Color(hex: "#FF7AA2"))
            .frame(width: 10, height: 10)
            .padding(.top, 6)
          VStack(alignment: .leading, spacing: 6) {
            Text(story.0).font(.system(size: 16, weight: .bold))
            Text(story.1).font(.system(size: 14, weight: .medium)).foregroundColor(.black.opacity(0.56)).lineSpacing(4)
          }
          Spacer()
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
      }
    }
  }
}
