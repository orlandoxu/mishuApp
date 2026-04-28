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
        ZStack {
          Circle()
            .fill(LinearGradient(colors: contact.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 64, height: 64)
            .shadow(color: contact.colors.last?.opacity(isActive ? 0.22 : 0.08) ?? .clear, radius: 16, x: 0, y: 8)
          Text(contact.avatarText)
            .font(.system(size: isActive ? 20 : 18, weight: .medium))
            .foregroundColor(.white)
            .frame(width: 64, height: 64, alignment: .center)
          if contact.isStarred {
            Image(systemName: "star.fill")
              .font(.system(size: 10, weight: .black))
              .foregroundColor(Color(hex: "#FBBF24"))
              .frame(width: 16, height: 16)
              .offset(x: 26, y: 26)
          }
        }
        .frame(width: 64, height: 64)
        .opacity(isActive ? 1 : 0.35)
        .scaleEffect(isActive ? 1 : 0.62)

        Text(contact.shortName)
          .font(.system(size: 12, weight: isActive ? .bold : .medium))
          .foregroundColor(Color.black.opacity(isActive ? 0.78 : 0.35))
          .frame(width: 74, alignment: .center)
          .offset(y: isActive ? 2 : 0)
      }
      .frame(width: 74, height: 96)
    }
    .buttonStyle(.plain)
  }
}

struct ContactDetailCard: View {
  let contact: PrototypeContact

  var body: some View {
    VStack(spacing: 24) {
      ContactGlassSection(title: "偏好指南", symbol: "gift.fill", color: Color(hex: "#F43F5E"), items: contact.preferences)
      ContactGlassSection(title: "能量图谱", symbol: "bolt.fill", color: Color(hex: "#3B82F6"), items: contact.resources)
      ContactInteractionSection(contact: contact)
    }
  }
}

struct ContactProfileSummary: View {
  let contact: PrototypeContact

  var body: some View {
    VStack(spacing: 16) {
      Text(contact.role)
        .font(.system(size: 14, weight: .medium))
        .foregroundColor(Color.black.opacity(0.40))
        .multilineTextAlignment(.center)

      HStack(spacing: 10) {
        ForEach(contact.tags, id: \.self) { tag in
          Text(tag)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(Color.black.opacity(0.40))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.60))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.black.opacity(0.03), lineWidth: 1))
        }
      }
    }
    .frame(maxWidth: .infinity)
  }
}

private struct ContactGlassSection: View {
  let title: String
  let symbol: String
  let color: Color
  let items: [String]

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      HStack(spacing: 10) {
        Image(systemName: symbol)
          .font(.system(size: 18, weight: .bold))
          .foregroundColor(color.opacity(0.82))
        Text(title)
          .font(.system(size: 17, weight: .bold))
          .foregroundColor(Color.black.opacity(0.84))
      }

      FlowTagLayout(items: items)
    }
    .padding(24)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color.white.opacity(0.40))
    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 28, style: .continuous)
        .stroke(Color.white.opacity(0.60), lineWidth: 1)
    )
    .shadow(color: Color.black.opacity(0.01), radius: 20, x: 0, y: 8)
  }
}

private struct ContactInsightCard: View {
  let text: String

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: "sparkles")
        .font(.system(size: 16, weight: .bold))
        .foregroundColor(Color(hex: "#8B5CF6").opacity(0.72))
      Text(text)
        .font(.system(size: 13, weight: .medium))
        .foregroundColor(Color(hex: "#312E81").opacity(0.62))
        .lineSpacing(4)
    }
    .padding(18)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color(hex: "#6366F1").opacity(0.035))
    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 20, style: .continuous)
        .stroke(Color(hex: "#6366F1").opacity(0.10), lineWidth: 1)
    )
  }
}

private struct ContactInteractionSection: View {
  let contact: PrototypeContact

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      HStack {
        HStack(spacing: 10) {
          Image(systemName: "arrow.left.arrow.right")
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(Color(hex: "#6366F1").opacity(0.82))
          Text("互动")
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(Color.black.opacity(0.85))
        }

        Spacer()

        Text("Interaction")
          .font(.system(size: 10, weight: .bold))
          .foregroundColor(Color.black.opacity(0.20))
          .tracking(1.6)
          .textCase(.uppercase)
      }

      ContactInsightCard(text: contact.insight)

      VStack(alignment: .leading, spacing: 16) {
        ForEach(Array(contact.interactions.enumerated()), id: \.offset) { index, item in
          HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 4) {
              Circle()
                .fill(Color(hex: "#818CF8"))
                .frame(width: 8, height: 8)
                .overlay(Circle().stroke(Color.white, lineWidth: 4))
              if index != contact.interactions.count - 1 {
                Rectangle()
                  .fill(Color.black.opacity(0.04))
                  .frame(width: 1)
              }
            }

            VStack(alignment: .leading, spacing: 8) {
              HStack(spacing: 8) {
                Text(index == 0 ? "2026.02.28" : "2026.01.10")
                  .font(.system(size: 11, weight: .bold))
                  .foregroundColor(Color.black.opacity(0.20))
                  .monospacedDigit()

                Text(index == 0 ? "日常互动" : "TA的引荐")
                  .font(.system(size: 10, weight: .bold))
                  .foregroundColor(Color(hex: "#6366F1"))
                  .padding(.horizontal, 8)
                  .padding(.vertical, 2)
                  .background(Color(hex: "#EEF2FF"))
                  .clipShape(Capsule())
              }

              Text(item)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.black.opacity(0.75))
                .lineSpacing(6)
            }
          }
        }
      }
      .padding(.leading, 4)
    }
    .padding(24)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color.white.opacity(0.40))
    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 32, style: .continuous)
        .stroke(Color.white.opacity(0.60), lineWidth: 1)
    )
    .shadow(color: Color.black.opacity(0.01), radius: 20, x: 0, y: 8)
  }
}

private struct FlowTagLayout: View {
  let items: [String]

  var body: some View {
    let columns = [
      GridItem(.adaptive(minimum: 118), spacing: 10, alignment: .leading)
    ]

    LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
      ForEach(items, id: \.self) { item in
        Text(item)
          .font(.system(size: 13, weight: .medium))
          .foregroundColor(Color.black.opacity(0.60))
          .lineLimit(2)
          .multilineTextAlignment(.leading)
          .padding(.horizontal, 14)
          .padding(.vertical, 10)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color.white.opacity(0.50))
          .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
          .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
              .stroke(Color.black.opacity(0.02), lineWidth: 1)
          )
      }
    }
  }
}
