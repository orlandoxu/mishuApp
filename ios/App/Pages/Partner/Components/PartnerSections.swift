import SwiftUI

struct PartnerIdentitySection: View {
  var body: some View {
    VStack(spacing: 16) {
      HStack(spacing: -20) {
        Image("avatar_girl")
          .resizable()
          .scaledToFill()
          .frame(width: 84, height: 84)
          .clipShape(Circle())
          .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 2)

        ZStack {
          Circle()
            .fill(Color.white)
            .frame(width: 84, height: 84)
            .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 4)
          VStack(spacing: 2) {
            Image(systemName: "plus")
              .font(.system(size: 22, weight: .medium))
              .foregroundColor(Color.black.opacity(0.30))
            Text("邀请 TA")
              .font(.system(size: 10, weight: .bold))
              .foregroundColor(Color.black.opacity(0.30))
          }
        }
      }

      VStack(spacing: 6) {
        HStack(spacing: 8) {
          Circle().fill(Color(hex: "#34D399")).frame(width: 8, height: 8)
          Text("32 Days Together")
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(Color.black.opacity(0.40))
            .tracking(2.0)
        }
      }

      HStack(spacing: 12) {
        Text("TA 的档案")
          .font(.system(size: 14, weight: .bold))
          .foregroundColor(Color.black.opacity(0.70))
          .padding(.horizontal, 24)
          .frame(height: 40)
          .background(Color.black.opacity(0.04))
          .clipShape(Capsule())

        Image(systemName: "ellipsis")
          .font(.system(size: 18, weight: .bold))
          .foregroundColor(Color.black.opacity(0.60))
          .frame(width: 40, height: 40)
          .background(Color.black.opacity(0.04))
          .clipShape(Circle())
      }
    }
    .padding(.top, 22)
    .padding(.bottom, 4)
    .frame(maxWidth: .infinity)
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
        HStack(alignment: .top, spacing: 14) {
          Image(story.0 == "第一次旅行" ? "avatar_boy" : "avatar_girl")
            .resizable()
            .scaledToFill()
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
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
