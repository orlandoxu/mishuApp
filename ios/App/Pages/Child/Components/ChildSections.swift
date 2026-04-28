import SwiftUI

struct ChildIdentitySection: View {
  var body: some View {
    VStack(spacing: 16) {
      ZStack {
        RoundedRectangle(cornerRadius: 36, style: .continuous)
          .fill(Color.white)
          .frame(width: 84, height: 84)
          .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 4)
        Image("img_card_child")
          .resizable()
          .scaledToFit()
          .frame(width: 72, height: 72)
      }

      VStack(spacing: 8) {
        HStack(spacing: 6) {
          Text("小糯米")
            .font(.system(size: 22, weight: .black))
            .foregroundColor(Color.black.opacity(0.90))
          Image(systemName: "pencil")
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(Color.black.opacity(0.40))
            .frame(width: 24, height: 24)
            .background(Color.black.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }

        HStack(spacing: 8) {
          Circle()
            .fill(Color.blue.opacity(0.75))
            .frame(width: 8, height: 8)
          Text("3岁 3个月 16天")
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(Color.black.opacity(0.40))
            .tracking(1.6)
        }
      }
    }
    .padding(24)
    .frame(maxWidth: .infinity)
    .background(Color.white)
    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
  }
}

struct GrowthMilestonesSection: View {
  private let milestones = ["第一次独立讲完整故事", "会认 12 个新字", "主动安慰同伴"]

  var body: some View {
    ChildCard(title: "成长里程碑", symbol: "flag.checkered") {
      ForEach(milestones, id: \.self) { item in
        Label(item, systemImage: "checkmark.circle.fill")
          .font(.system(size: 15, weight: .semibold))
          .foregroundColor(Color.black.opacity(0.66))
      }
    }
  }
}

struct ChildFootprintsSection: View {
  private let footprints = ["周一：在公园观察蚂蚁搬家", "周三：画了一辆绿色火车", "今天：睡前问月亮为什么会跟着走"]

  var body: some View {
    ChildCard(title: "成长足迹", symbol: "sparkles") {
      ForEach(footprints, id: \.self) { item in
        Text(item)
          .font(.system(size: 15, weight: .medium))
          .foregroundColor(Color.black.opacity(0.62))
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(14)
          .background(Color.black.opacity(0.035))
          .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
      }
    }
  }
}

private struct ChildCard<Content: View>: View {
  let title: String
  let symbol: String
  let content: Content

  init(title: String, symbol: String, @ViewBuilder content: () -> Content) {
    self.title = title
    self.symbol = symbol
    self.content = content()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Label(title, systemImage: symbol)
        .font(.system(size: 18, weight: .black))
        .foregroundColor(Color.black.opacity(0.80))
      VStack(alignment: .leading, spacing: 12) {
        content
      }
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color.white)
    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
  }
}
