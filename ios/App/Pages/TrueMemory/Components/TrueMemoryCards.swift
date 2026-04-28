import SwiftUI

struct TrueMemoryItem: Identifiable {
  let id: String
  let text: String
  let time: String
  let category: String
}

struct TrueMemoryCategoryButton: View {
  let title: String
  let imageName: String?
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 6) {
        if let imageName {
          Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20)
            .opacity(isSelected ? 1 : 0.40)
        }
        Text(title)
      }
      .font(.system(size: 14, weight: .black))
      .foregroundColor(isSelected ? Color.black.opacity(0.82) : Color.black.opacity(0.30))
      .frame(minWidth: imageName == nil ? 100 : nil)
      .padding(.horizontal, 16)
      .padding(.vertical, 10)
      .background(isSelected ? Color.white : Color.white.opacity(0.40))
      .clipShape(Capsule())
      .shadow(color: isSelected ? Color.pink.opacity(0.12) : .clear, radius: 12, x: 0, y: 6)
    }
    .buttonStyle(.plain)
  }
}

struct TrueMemoryTimelineCard: View {
  let item: TrueMemoryItem

  var body: some View {
    ZStack(alignment: .topLeading) {
      Circle()
        .fill(Color.white)
        .frame(width: 12, height: 12)
        .overlay(Circle().stroke(Color(hex: "#FF4B8B"), lineWidth: 3))
        .offset(x: 2, y: 48)
        .zIndex(2)

      if let iconName = categoryIconName {
        Image(iconName)
          .resizable()
          .scaledToFit()
          .frame(width: 48, height: 48)
          .offset(x: 56, y: -24)
          .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
          .zIndex(3)
      }

      VStack(alignment: .leading, spacing: 0) {
        HStack {
          Text(item.category)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(categoryColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(categoryColor.opacity(0.12))
            .clipShape(Capsule())
          Spacer()
          HStack(spacing: 6) {
            Image(systemName: "trash")
              .font(.system(size: 13, weight: .bold))
            Text("遗忘")
              .font(.system(size: 13, weight: .bold))
          }
          .foregroundColor(Color.black.opacity(0.30))
        }
        .padding(.bottom, 12)

        Text("\"\(item.text)\"")
          .font(.system(size: 17, weight: .semibold))
          .foregroundColor(Color.black.opacity(0.85))
          .lineSpacing(6)
          .tracking(-0.2)
          .padding(.bottom, 16)

        HStack(spacing: 6) {
          Image(systemName: "clock")
            .font(.system(size: 13, weight: .semibold))
          Text(item.time)
            .font(.system(size: 11, weight: .bold))
        }
        .foregroundColor(Color.black.opacity(0.40))
      }
      .padding(.top, 22)
      .padding(.horizontal, 20)
      .padding(.bottom, 20)
      .background(Color.white.opacity(0.30))
      .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 32, style: .continuous)
          .stroke(Color.white.opacity(0.60), lineWidth: 1)
      )
      .shadow(color: Color.black.opacity(0.03), radius: 32, x: 0, y: 8)
      .padding(.leading, 32)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var categoryColor: Color {
    switch item.category {
    case "个人信息":
      return Color(hex: "#7C3AED")
    case "安全备忘":
      return Color(hex: "#F97316")
    case "旅行计划":
      return Color(hex: "#0D9488")
    default:
      return Color(hex: "#64748B")
    }
  }

  private var categoryIconName: String? {
    switch item.category {
    case "个人信息":
      return "img_memory_robot"
    case "安全备忘":
      return "img_memory_memo"
    case "旅行计划":
      return "img_memory_travel"
    default:
      return nil
    }
  }
}
