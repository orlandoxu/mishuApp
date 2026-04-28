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
      .padding(.horizontal, 15)
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
    HStack(alignment: .top, spacing: 16) {
      VStack(spacing: 0) {
        Circle()
          .fill(Color.white)
          .frame(width: 14, height: 14)
          .overlay(Circle().stroke(Color(hex: "#FF4B8B"), lineWidth: 4))
        Rectangle()
          .fill(Color.black.opacity(0.04))
          .frame(width: 1)
      }

      VStack(alignment: .leading, spacing: 12) {
        HStack {
          if let iconName = categoryIconName {
            Image(iconName)
              .resizable()
              .scaledToFit()
              .frame(width: 30, height: 30)
          }
          Text(item.category)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(categoryColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(categoryColor.opacity(0.12))
            .clipShape(Capsule())
          Spacer()
          Label("遗忘", systemImage: "trash")
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(Color.black.opacity(0.30))
        }

        Text("\"\(item.text)\"")
          .font(.system(size: 17, weight: .semibold))
          .foregroundColor(Color.black.opacity(0.84))
          .lineSpacing(5)

        Label(item.time, systemImage: "clock")
          .font(.system(size: 12, weight: .medium))
          .foregroundColor(Color.black.opacity(0.40))
      }
      .padding(18)
      .background(Color.white.opacity(0.40))
      .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 28, style: .continuous)
          .stroke(Color.white.opacity(0.70), lineWidth: 1)
      )
    }
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
