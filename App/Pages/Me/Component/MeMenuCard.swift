import SwiftUI

struct MeMenuCard<Content: View>: View {
  let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    VStack(spacing: 0) {
      content
    }
    .background(Color.white)
    .cornerRadius(12)
  }
}

struct MeMenuRow<RightContent: View>: View {
  let icon: String
  let title: String
  let rightContent: RightContent
  let onTap: () -> Void

  init(
    icon: String,
    title: String,
    @ViewBuilder rightContent: () -> RightContent = {
      Image("icon_more_arrow")
        .resizable()
        .scaledToFit()
        .frame(width: 12, height: 12)
        .foregroundColor(Color(hex: "0xCCCCCC"))
    },
    onTap: @escaping () -> Void
  ) {
    self.icon = icon
    self.title = title
    self.rightContent = rightContent()
    self.onTap = onTap
  }

  var body: some View {
    Button {
      onTap()
    } label: {
      HStack(spacing: 12) {
        Image(icon)
          .resizable()
          .scaledToFit()
          .frame(width: 24, height: 24)

        Text(title)
          .font(.system(size: 16, weight: .medium))
          .foregroundColor(Color(hex: "0x111111"))

        Spacer(minLength: 0)

        rightContent
      }
      .padding(.horizontal, 16)
      .frame(height: 56)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}

struct MeMenuDivider: View {
  var body: some View {
    Rectangle()
      .fill(Color(hex: "0xF5F5F5"))
      .frame(height: 1)
      .padding(.leading, 52)
  }
}
