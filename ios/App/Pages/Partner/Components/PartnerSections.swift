import SwiftUI

struct PartnerIdentitySection: View {
  var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: -20) {
        ZStack {
          Circle()
            .fill(Color.white)
            .frame(width: 84, height: 84)
          Image("avatar_girl")
            .resizable()
            .scaledToFill()
            .frame(width: 84, height: 84)
            .clipShape(Circle())
        }
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
              .padding(.bottom, 2)
            Text("邀请 TA")
              .font(.system(size: 10, weight: .bold))
              .foregroundColor(Color.black.opacity(0.30))
              .tracking(1.2)
          }
        }
      }
      .padding(.bottom, 20)

      HStack(spacing: 10) {
          Circle().fill(Color(hex: "#34D399")).frame(width: 8, height: 8)
          Text("32 Days Together")
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(Color.black.opacity(0.40))
            .textCase(.uppercase)
            .tracking(2.6)
      }
      .padding(.bottom, 24)

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
    .padding(.top, 24)
    .padding(.bottom, 56)
    .frame(maxWidth: .infinity)
  }
}

struct PartnerTimelineSection: View {
  private let stories: [PartnerStory] = [
    PartnerStory(date: "2026.11.05", content: "最近大家都稍微有点忙，感觉距离拉远了一些。希望这只是暂时的冷淡期，相信很快就会好起来的。", icon: "snowflake", color: Color(hex: "#60A5FA"), avatar: "avatar_boy"),
    PartnerStory(date: "2026.09.12", content: "今天因为一些生活琐事拌嘴了，两个人都不开心。其实心里都不想让对方难过，只是需要时间。", icon: "cloud.rain.fill", color: Color(hex: "#818CF8"), avatar: "avatar_girl"),
    PartnerStory(date: "2026.04.15", content: "看完夜场电影走在冷风里，TA 第一次主动把我的手揣进大衣口袋里。掌心出汗，但不想松开。", icon: "flame.fill", color: Color(hex: "#FB7185"), avatar: "avatar_boy"),
    PartnerStory(date: "2025.12.24", content: "平安夜一起散步，TA 突然停下来认真地帮我整理被风吹乱的围巾。那个瞬间，心脏漏跳了一拍。", icon: "heart.fill", color: Color(hex: "#F472B6"), avatar: "avatar_girl"),
    PartnerStory(date: "2025.05.20", content: "今天下午在那家转角的咖啡店，我们第一次见面，意外地聊得很懂对方。故事的开始。", icon: "play.fill", color: Color(hex: "#34D399"), avatar: "avatar_girl")
  ]

  var body: some View {
    ZStack(alignment: .topLeading) {
      Rectangle()
        .fill(
          LinearGradient(
            colors: [Color.black.opacity(0.10), Color.black.opacity(0.05), Color.clear],
            startPoint: .top,
            endPoint: .bottom
          )
        )
        .frame(width: 1)
        .padding(.leading, 20)
        .padding(.top, 60)
        .padding(.bottom, 16)

      VStack(alignment: .leading, spacing: 0) {
        HStack {
          Text("我们的故事")
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(Color.black.opacity(0.90))
          Spacer()
          Text("AI Auto-tracked")
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(Color.black.opacity(0.30))
            .textCase(.uppercase)
            .tracking(1.1)
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 16)
        .overlay(alignment: .bottom) {
          Rectangle()
            .fill(Color.black.opacity(0.05))
            .frame(height: 1)
        }
        .padding(.bottom, 32)

        VStack(spacing: 32) {
          ForEach(stories) { story in
            HStack(alignment: .top, spacing: 16) {
              Image(story.avatar)
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 1))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)

              VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                  Text(story.date)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.black.opacity(0.30))
                    .tracking(1.6)
                  Rectangle()
                    .fill(Color.black.opacity(0.03))
                    .frame(height: 1)
                }

                ZStack(alignment: .bottomTrailing) {
                  Text("\"")
                    .font(.system(size: 80, weight: .black, design: .serif))
                    .foregroundColor(Color.black.opacity(0.02))
                    .offset(x: -2, y: -32)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

                  Text(story.content)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.black.opacity(0.75))
                    .lineSpacing(9)
                    .tracking(0.4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 12)

                  Image(systemName: story.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(story.color.opacity(0.30))
                }
                .padding(.top, 20)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .background(Color.white.opacity(0.70))
                .clipShape(RoundedCorner(radius: 24, corners: [.topRight, .bottomLeft, .bottomRight]))
                .overlay(
                  RoundedCorner(radius: 24, corners: [.topRight, .bottomLeft, .bottomRight])
                    .stroke(Color.white, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.02), radius: 24, x: 0, y: 4)
              }
            }
          }
        }
      }
    }
    .padding(.horizontal, 20)
    .padding(.top, 32)
  }
}

private struct PartnerStory: Identifiable {
  let id = UUID()
  let date: String
  let content: String
  let icon: String
  let color: Color
  let avatar: String
}
