import SwiftUI

struct PrototypeContact: Identifiable, Hashable {
  let id: String
  let name: String
  let shortName: String
  let role: String
  let avatarText: String
  let isStarred: Bool
  let colors: [Color]
  let tags: [String]
  let preferences: [String]
  let resources: [String]
  let insight: String
  let interactions: [String]
}

struct ContactAvatarButton: View {
  let contact: PrototypeContact
  let isActive: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 8) {
        ZStack(alignment: .bottomTrailing) {
          Circle()
            .fill(LinearGradient(colors: contact.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: isActive ? 64 : 44, height: isActive ? 64 : 44)
            .shadow(color: contact.colors.last?.opacity(isActive ? 0.22 : 0.08) ?? .clear, radius: 16, x: 0, y: 8)
          Text(contact.avatarText)
            .font(.system(size: isActive ? 20 : 16, weight: .bold))
            .foregroundColor(.white)
          if contact.isStarred {
            Image(systemName: "star.fill")
              .font(.system(size: 10, weight: .black))
              .foregroundColor(Color(hex: "#FBBF24"))
              .offset(x: 2, y: 2)
          }
        }
        .opacity(isActive ? 1 : 0.35)

        Text(contact.shortName)
          .font(.system(size: 12, weight: isActive ? .bold : .medium))
          .foregroundColor(Color.black.opacity(isActive ? 0.78 : 0.35))
      }
      .frame(width: 74)
    }
    .buttonStyle(.plain)
  }
}

struct ContactDetailCard: View {
  let contact: PrototypeContact

  var body: some View {
    VStack(alignment: .leading, spacing: 22) {
      VStack(alignment: .leading, spacing: 8) {
        HStack(alignment: .firstTextBaseline) {
          Text(contact.name)
            .font(.system(size: 34, weight: .black))
            .foregroundColor(Color.black.opacity(0.84))
          if contact.isStarred {
            Image(systemName: "star.fill")
              .font(.system(size: 16, weight: .bold))
              .foregroundColor(Color(hex: "#FBBF24"))
          }
        }
        Text(contact.role)
          .font(.system(size: 14, weight: .medium))
          .foregroundColor(Color.black.opacity(0.42))
      }

      tagRow(contact.tags)

      section(title: "偏好", items: contact.preferences, symbol: "sparkles")
      section(title: "可连接资源", items: contact.resources, symbol: "gift.fill")

      VStack(alignment: .leading, spacing: 10) {
        Label("Aura 洞察", systemImage: "wand.and.stars")
          .font(.system(size: 14, weight: .black))
          .foregroundColor(Color(hex: "#8C7CF0"))
        Text(contact.insight)
          .font(.system(size: 15, weight: .semibold))
          .foregroundColor(Color.black.opacity(0.68))
          .lineSpacing(5)
      }
      .padding(18)
      .background(Color(hex: "#F5F2FF"))
      .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

      section(title: "关键互动", items: contact.interactions, symbol: "arrow.left.arrow.right")
    }
    .padding(22)
    .background(Color.white.opacity(0.72))
    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 32, style: .continuous)
        .stroke(Color.white, lineWidth: 1)
    )
    .shadow(color: Color.black.opacity(0.04), radius: 22, x: 0, y: 10)
  }

  private func tagRow(_ tags: [String]) -> some View {
    HStack(spacing: 8) {
      ForEach(tags, id: \.self) { tag in
        Text(tag)
          .font(.system(size: 12, weight: .bold))
          .foregroundColor(Color.black.opacity(0.52))
          .padding(.horizontal, 12)
          .padding(.vertical, 7)
          .background(Color.black.opacity(0.04))
          .clipShape(Capsule())
      }
    }
  }

  private func section(title: String, items: [String], symbol: String) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Label(title, systemImage: symbol)
        .font(.system(size: 14, weight: .black))
        .foregroundColor(Color.black.opacity(0.72))
      VStack(alignment: .leading, spacing: 8) {
        ForEach(items, id: \.self) { item in
          Text(item)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(Color.black.opacity(0.62))
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.black.opacity(0.035))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
      }
    }
  }
}
