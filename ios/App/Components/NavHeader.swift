import SwiftUI

struct NavHeader<Trailing: View>: View {
  let title: String
  let trailing: Trailing
  let onBack: (() -> Void)?
  let showsTrailingChrome: Bool
  let topPadding: CGFloat
  let bottomPadding: CGFloat

  @ObservedObject private var appNavigation = AppNavigationModel.shared
  @Environment(\.presentationMode) private var presentationMode
  @State private var containerSafeAreaTop: CGFloat = 0

  init(
    title: String,
    onBack: (() -> Void)? = nil,
    topPadding: CGFloat = 8,
    bottomPadding: CGFloat = 16,
    @ViewBuilder trailing: () -> Trailing
  ) {
    self.title = title
    self.onBack = onBack
    self.trailing = trailing()
    self.topPadding = topPadding
    self.bottomPadding = bottomPadding
    showsTrailingChrome = true
  }

  init(
    title: String,
    onBack: (() -> Void)? = nil,
    topPadding: CGFloat = 8,
    bottomPadding: CGFloat = 16
  ) where Trailing == EmptyView {
    self.title = title
    self.onBack = onBack
    self.topPadding = topPadding
    self.bottomPadding = bottomPadding
    trailing = EmptyView()
    showsTrailingChrome = false
  }

  var body: some View {
    HStack(spacing: 0) {
      Button {
        if let onBack {
          onBack()
        } else {
          if appNavigation.path.isEmpty {
            presentationMode.wrappedValue.dismiss()
          } else {
            appNavigation.pop()
          }
        }
      } label: {
        ZStack {
          RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color.white.opacity(0.30))
            .overlay(
              RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.60), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 16, x: 0, y: 8)
          Image(systemName: "arrow.left")
            .font(.system(size: 24, weight: .semibold))
            .foregroundColor(Color.black.opacity(0.82))
        }
        .frame(width: 48, height: 48)
      }
      .buttonStyle(.plain)

      if !title.isEmpty {
        Text(title)
          .font(.system(size: 20, weight: .black))
          .foregroundColor(Color.black.opacity(0.80))
          .lineLimit(1)
          .frame(maxWidth: .infinity)
      } else {
        Spacer()
      }

      trailingSlot
    }
    .padding(.horizontal, 24)
    .padding(.top, containerSafeAreaTop + topPadding)
    .padding(.bottom, bottomPadding)
    .frame(maxWidth: .infinity)
    .background(
      GeometryReader { proxy in
        Color.clear
          .preference(key: NavHeaderSafeAreaTopKey.self, value: proxy.safeAreaInsets.top)
      }
    )
    .onPreferenceChange(NavHeaderSafeAreaTopKey.self) { value in
      containerSafeAreaTop = value
    }
  }

  @ViewBuilder
  private var trailingSlot: some View {
    if showsTrailingChrome {
      trailing
        .frame(width: 48, height: 48)
        .background(Color.white.opacity(0.30))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
          RoundedRectangle(cornerRadius: 24, style: .continuous)
            .stroke(Color.white.opacity(0.60), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 16, x: 0, y: 8)
    } else {
      Color.clear.frame(width: 48, height: 48)
    }
  }
}

private struct NavHeaderSafeAreaTopKey: PreferenceKey {
  static var defaultValue: CGFloat = 0

  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = nextValue()
  }
}
