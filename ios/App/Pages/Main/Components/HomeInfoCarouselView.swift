import SwiftUI

struct HomeInfoCarouselView: View {
  let onOpenPro: () -> Void

  var body: some View {
    TabView {
      HomeProBannerView(onOpenPro: onOpenPro)
        .padding(.horizontal, 20)

      HomeGrowthSummaryView()
        .padding(.horizontal, 20)
    }
    .tabViewStyle(.page(indexDisplayMode: .automatic))
    .frame(height: 176)
  }
}

private struct HomeProBannerView: View {
  let onOpenPro: () -> Void

  var body: some View {
    Button(action: onOpenPro) {
      ZStack(alignment: .topLeading) {
        Image("img_main_ad_background")
          .resizable()
          .scaledToFill()

        VStack(alignment: .leading, spacing: 10) {
          HStack {
            Text("限时特惠")
              .font(.system(size: 11, weight: .black))
              .foregroundColor(.white)
              .padding(.horizontal, 10)
              .padding(.vertical, 5)
              .background(Color(hex: "#FF7171"))
              .clipShape(Capsule())

            Spacer()

            Text("仅剩 23:59:59")
              .font(.system(size: 11, weight: .black, design: .monospaced))
              .foregroundColor(Color(hex: "#FF4B4B"))
              .padding(.horizontal, 10)
              .padding(.vertical, 5)
              .background(Color.white.opacity(0.55))
              .clipShape(Capsule())
          }

          VStack(alignment: .leading, spacing: 4) {
            Text("开通 Pro 会员")
              .font(.system(size: 23, weight: .black))
              .foregroundColor(Color.black.opacity(0.82))
            Text("解锁全部功能，体验更智能的 Aura")
              .font(.system(size: 12, weight: .bold))
              .foregroundColor(Color.black.opacity(0.50))
          }

          Spacer()

          HStack(spacing: 12) {
            HomeBannerFeature(icon: "bubble.left.and.bubble.right.fill", text: "无限次对话")
            HomeBannerFeature(icon: "externaldrive.fill", text: "专属记忆")
            Spacer()
            Text("立即开通")
              .font(.system(size: 13, weight: .black))
              .foregroundColor(.white)
              .padding(.horizontal, 14)
              .padding(.vertical, 8)
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
        .padding(16)
      }
      .frame(maxWidth: .infinity)
      .frame(height: 160)
      .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 32, style: .continuous)
          .stroke(Color.white, lineWidth: 4)
      )
      .shadow(color: Color.black.opacity(0.04), radius: 24, x: 0, y: 10)
    }
    .buttonStyle(.plain)
  }
}

private struct HomeBannerFeature: View {
  let icon: String
  let text: String

  var body: some View {
    HStack(spacing: 5) {
      Image(systemName: icon)
        .font(.system(size: 10, weight: .bold))
        .foregroundColor(Color(hex: "#FF4B8B"))
        .frame(width: 16, height: 16)
        .background(Color(hex: "#FFE0EC"))
        .clipShape(Circle())
      Text(text)
        .font(.system(size: 10, weight: .black))
        .foregroundColor(Color.black.opacity(0.60))
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
