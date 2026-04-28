import SwiftUI

struct HomeInfoCarouselView: View {
  let onOpenPro: () -> Void

  var body: some View {
    TabView {
      HomeProBannerView(onOpenPro: onOpenPro)
        .padding(.horizontal, 30)

      HomeGrowthSummaryView()
        .padding(.horizontal, 30)
    }
    .tabViewStyle(.page(indexDisplayMode: .automatic))
    .frame(height: 168)
  }
}

private struct HomeProBannerView: View {
  let onOpenPro: () -> Void

  var body: some View {
    Button(action: onOpenPro) {
      ZStack(alignment: .topLeading) {
        GeometryReader { proxy in
          Image("img_main_ad_background")
            .resizable()
            .scaledToFill()
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }

        VStack(alignment: .leading, spacing: 0) {
          HStack {
            Text("🔥 限时特惠")
              .font(.system(size: 12, weight: .black))
              .foregroundColor(.white)
              .padding(.horizontal, 11)
              .padding(.vertical, 7)
              .background(Color(hex: "#FF686D"))
              .clipShape(Capsule())
              .shadow(color: Color(hex: "#FF686D").opacity(0.28), radius: 10, x: 0, y: 5)

            Spacer()

            Text("⏰ 仅剩 23:58:59")
              .font(.system(size: 12, weight: .black, design: .monospaced))
              .foregroundColor(Color(hex: "#FF4F58"))
              .padding(.horizontal, 12)
              .padding(.vertical, 7)
              .background(Color.white.opacity(0.62))
              .clipShape(Capsule())
          }
          .padding(.bottom, 20)

          VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 0) {
              Text("开通 ")
                .foregroundColor(Color.black.opacity(0.82))
              Text("Pro")
                .foregroundColor(Color(hex: "#FF4386"))
              Text(" 会员")
                .foregroundColor(Color.black.opacity(0.82))
            }
            .font(.system(size: 24, weight: .black))

            Text("解锁全部功能，体验更智能的 Aura")
              .font(.system(size: 13, weight: .bold))
              .foregroundColor(Color.black.opacity(0.48))
              .lineLimit(1)
              .minimumScaleFactor(0.9)
          }

          Spacer()

          HStack(alignment: .center, spacing: 12) {
            HStack(spacing: 12) {
              HomeBannerFeature(icon: "bubble.left.and.bubble.right.fill", text: "无限次对话")
              HomeBannerFeature(icon: "cylinder.split.1x2.fill", text: "专属记忆")
            }
            .layoutPriority(1)

            Spacer()

            HStack(spacing: 6) {
              Text("立即开通")
              Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .black))
            }
            .font(.system(size: 13, weight: .black))
            .foregroundColor(.white)
            .lineLimit(1)
            .frame(width: 108, height: 42)
            .background(
              LinearGradient(
                colors: [Color(hex: "#FF73A1"), Color(hex: "#FF4386")],
                startPoint: .leading,
                endPoint: .trailing
              )
            )
            .clipShape(Capsule())
          }
        }
        .padding(.top, 26)
        .padding(.leading, 14)
        .padding(.trailing, 24)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      }
      .frame(maxWidth: .infinity)
      .frame(height: 156)
      .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 40, style: .continuous)
          .stroke(Color.white, lineWidth: 4)
      )
      .shadow(color: Color.black.opacity(0.04), radius: 22, x: 0, y: 10)
    }
    .buttonStyle(.plain)
  }
}

private struct HomeBannerFeature: View {
  let icon: String
  let text: String

  var body: some View {
    HStack(spacing: 6) {
      Image(systemName: icon)
        .font(.system(size: 10, weight: .bold))
        .foregroundColor(Color(hex: "#FF4B8B"))
        .frame(width: 17, height: 17)
        .background(Color(hex: "#FFE8F1"))
        .clipShape(Circle())
      Text(text)
        .font(.system(size: 11, weight: .black))
        .foregroundColor(Color.black.opacity(0.60))
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: false)
    }
  }
}

private struct HomeGrowthSummaryView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("小宝贝成长摘要")
            .font(.system(size: 21, weight: .black))
            .foregroundColor(Color.black.opacity(0.82))
          Text("Aura 记录了 3 个新瞬间")
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(Color.black.opacity(0.45))
        }
        Spacer()
        Image(systemName: "sparkles")
          .font(.system(size: 22, weight: .bold))
          .foregroundColor(Color(hex: "#F472B6"))
      }

      HStack(spacing: 10) {
        HomeSummaryPill(title: "新词汇", value: "12")
        HomeSummaryPill(title: "好奇提问", value: "8")
        HomeSummaryPill(title: "开心时刻", value: "5")
      }
    }
    .padding(18)
    .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
    .background(
      LinearGradient(
        colors: [Color(hex: "#EEF7FF"), Color(hex: "#FFF0F7")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    )
    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 32, style: .continuous)
        .stroke(Color.white, lineWidth: 4)
    )
  }
}

private struct HomeSummaryPill: View {
  let title: String
  let value: String

  var body: some View {
    VStack(spacing: 4) {
      Text(value)
        .font(.system(size: 20, weight: .black))
        .foregroundColor(Color.black.opacity(0.78))
      Text(title)
        .font(.system(size: 11, weight: .bold))
        .foregroundColor(Color.black.opacity(0.42))
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 12)
    .background(Color.white.opacity(0.55))
    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
  }
}
