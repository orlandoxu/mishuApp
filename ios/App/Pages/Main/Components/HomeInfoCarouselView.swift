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
    .frame(height: 160)
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
              .font(.system(size: 10, weight: .black))
              .foregroundColor(.white)
              .padding(.horizontal, 10)
              .padding(.vertical, 4)
              .background(Color(hex: "#FF7171"))
              .clipShape(Capsule())
              .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)

            Spacer()

            Text("⏰ 仅剩 23:58:59")
              .font(.system(size: 10, weight: .black, design: .monospaced))
              .foregroundColor(Color(hex: "#FF4B4B"))
              .padding(.horizontal, 10)
              .padding(.vertical, 4)
              .background(Color.white.opacity(0.40))
              .clipShape(Capsule())
          }
          .padding(.bottom, 4)

          VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 0) {
              Text("开通 ")
                .foregroundColor(Color(hex: "#2D2D2D"))
              Text("Pro")
                .foregroundColor(Color(hex: "#FF4081"))
              Text(" 会员")
                .foregroundColor(Color(hex: "#2D2D2D"))
            }
            .font(.system(size: 22, weight: .black))

            Text("解锁全部功能，体验更智能的 Aura ✨")
              .font(.system(size: 11.5, weight: .bold))
              .foregroundColor(Color.black.opacity(0.50))
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
            .font(.system(size: 12, weight: .black))
            .foregroundColor(.white)
            .lineLimit(1)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
              LinearGradient(
                colors: [Color(hex: "#FF7BA3"), Color(hex: "#FF4B8B")],
                startPoint: .leading,
                endPoint: .trailing
              )
            )
            .clipShape(Capsule())
          }
        }
        .padding(.top, 12)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      }
      .frame(maxWidth: .infinity)
      .frame(height: 160)
      .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 32, style: .continuous)
          .stroke(Color.white, lineWidth: 4)
      )
      .shadow(color: Color.black.opacity(0.04), radius: 30, x: 0, y: 8)
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
        .frame(width: 14, height: 14)
        .background(Color(hex: "#FFE8F1"))
        .clipShape(Circle())
      Text(text)
        .font(.system(size: 10, weight: .black))
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
