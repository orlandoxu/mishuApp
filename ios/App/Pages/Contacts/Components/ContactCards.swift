import SwiftUI

struct PrototypeContact: Identifiable, Hashable {
  struct Interaction: Hashable {
    let id: String?
    let date: String
    let type: String
    let desc: String

    init(id: String? = nil, date: String, type: String, desc: String) {
      self.id = id
      self.date = date
      self.type = type
      self.desc = desc
    }
  }

  let id: String
  let name: String
  let shortName: String
  let age: Int
  let gender: String
  let role: String
  let avatarText: String
  let isStarred: Bool
  let starredAt: String?
  let colors: [Color]
  let tags: [String]
  let birthday: String?
  let relationship: String?
  let preferences: [String]
  let resources: [String]
  let insight: String
  let interactions: [Interaction]

  var compactRole: String {
    role.components(separatedBy: " @").first ?? role
  }
}

private let contactInteractionColorMap: [String: (bg: Color, text: Color)] = [
  "问候": (Color(hex: "#FEF3C7"), Color(hex: "#A16207")),
  "约定": (Color(hex: "#DBEAFE"), Color(hex: "#1D4ED8")),
  "钱款往来": (Color(hex: "#DCFCE7"), Color(hex: "#15803D")),
  "礼物赠送": (Color(hex: "#FFE4E6"), Color(hex: "#BE123C")),
  "重要事情": (Color(hex: "#FEE2E2"), Color(hex: "#B91C1C")),
  "聚会": (Color(hex: "#FFEDD5"), Color(hex: "#C2410C")),
  "帮忙": (Color(hex: "#E0E7FF"), Color(hex: "#4338CA")),
  "记忆": (Color(hex: "#E2E8F0"), Color(hex: "#334155"))
]

func contactInteractionStyle(for type: String) -> (bg: Color, text: Color) {
  contactInteractionColorMap[type] ?? (Color.black.opacity(0.06), Color.black.opacity(0.55))
}

struct ContactTopAvatarItem: View {
  let contact: PrototypeContact
  let isActive: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 6) {
        ZStack {
          Circle()
            .fill(LinearGradient(colors: contact.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 44, height: 44)
          Text(contact.avatarText)
            .font(.system(size: isActive ? 15 : 14, weight: .medium))
            .foregroundColor(.white)
          if contact.isStarred {
            ZStack {
              Circle().fill(.white).frame(width: 14, height: 14)
              Image(systemName: "star.fill")
                .font(.system(size: 8, weight: .black))
                .foregroundColor(Color(hex: "#F59E0B"))
            }
            .offset(x: 16, y: 16)
          }
        }
        .opacity(isActive ? 1 : 0.4)
        .scaleEffect(isActive ? 1.1 : 0.9)
        .shadow(color: (contact.colors.last ?? .clear).opacity(isActive ? 0.16 : 0.04), radius: 6, x: 0, y: 2)
      }
      .frame(width: 46, height: 52)
    }
    .buttonStyle(.plain)
  }
}

struct ContactTimelineCard: View {
  let interaction: PrototypeContact.Interaction
  let onCopy: () -> Void
  let onDelete: () -> Void

  var year: String { String(interaction.date.prefix(4)) }

  var monthDay: String {
    guard interaction.date.count > 5 else { return interaction.date }
    return String(interaction.date.dropFirst(5))
  }

  var body: some View {
    let style = contactInteractionStyle(for: interaction.type)
    HStack(alignment: .top, spacing: 13) {
      VStack(alignment: .leading, spacing: 5) {
        Text(year)
          .font(.system(size: 17, weight: .bold))
          .foregroundColor(Color.black.opacity(0.80))
          .fixedSize(horizontal: true, vertical: false)
        Text(monthDay)
          .font(.system(size: 12, weight: .medium))
          .foregroundColor(Color.black.opacity(0.48))
          .monospacedDigit()
          .fixedSize(horizontal: true, vertical: false)
      }
      .frame(width: 48, alignment: .leading)

      VStack(alignment: .leading, spacing: 11) {
        Text(interaction.desc)
          .font(.system(size: 16, weight: .medium))
          .foregroundColor(Color.black.opacity(0.80))
          .lineSpacing(5)
        HStack {
          Text(interaction.type)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(style.text)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(style.bg)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
          Spacer()
          HStack(spacing: 4) {
            Button(action: onCopy) {
              Image(systemName: "doc.on.doc")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Color.black.opacity(0.30))
                .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            Button(action: onDelete) {
              Image(systemName: "trash")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Color.black.opacity(0.30))
                .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
          }
        }
      }
      .padding(15)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Color.white.opacity(0.62))
      .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .stroke(Color.black.opacity(0.04), lineWidth: 1)
      )
      .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 2)
    }
  }
}

struct ContactListRow: View {
  let contact: PrototypeContact
  let action: () -> Void
  let isLast: Bool

  @State private var isStarred: Bool

  init(contact: PrototypeContact, action: @escaping () -> Void, isLast: Bool) {
    self.contact = contact
    self.action = action
    self.isLast = isLast
    _isStarred = State(initialValue: contact.isStarred)
  }

  var body: some View {
    HStack(spacing: 12) {
      Button(action: action) {
        HStack(spacing: 14) {
          ZStack {
            Circle()
              .fill(LinearGradient(colors: contact.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
              .frame(width: 46, height: 46)
            Text(contact.avatarText)
              .font(.system(size: 14, weight: .bold))
              .foregroundColor(.white)
          }
          VStack(alignment: .leading, spacing: 2) {
            Text(contact.name)
              .font(.system(size: 16, weight: .bold))
              .foregroundColor(Color.black.opacity(0.90))
            Text(contact.compactRole)
              .font(.system(size: 13, weight: .medium))
              .foregroundColor(Color.black.opacity(0.42))
              .lineLimit(1)
          }
          Spacer()
        }
      }
      .buttonStyle(.plain)

      Button {
        isStarred.toggle()
      } label: {
        Image(systemName: isStarred ? "star.fill" : "star")
          .font(.system(size: 18, weight: .semibold))
          .foregroundColor(isStarred ? Color(hex: "#F59E0B") : Color.black.opacity(0.20))
          .frame(width: 28, height: 28)
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 12)
    .background(Color.white.opacity(0.96))
    .overlay(alignment: .bottom) {
      if !isLast {
        Rectangle()
          .fill(Color.black.opacity(0.04))
          .frame(height: 1)
          .padding(.leading, 80)
      }
    }
  }
}
