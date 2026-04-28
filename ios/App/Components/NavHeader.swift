import SwiftUI

struct NavHeader<Trailing: View>: View {
  let title: String
  let trailing: Trailing
  let onBack: (() -> Void)?
  let showsTrailingChrome: Bool

  @ObservedObject private var appNavigation = AppNavigationModel.shared
  @Environment(\.presentationMode) private var presentationMode

  init(title: String, onBack: (() -> Void)? = nil, @ViewBuilder trailing: () -> Trailing) {
    self.title = title
    self.onBack = onBack
    self.trailing = trailing()
    showsTrailingChrome = true
  }

  init(title: String, onBack: (() -> Void)? = nil) where Trailing == EmptyView {
    self.title = title
    self.onBack = onBack
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
    .padding(.top, safeAreaTop + 10)
    .padding(.bottom, 14)
    .frame(maxWidth: .infinity)
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

private struct LegacyNavHeader<Trailing: View>: View {
  let title: String
  let trailing: Trailing
  let onBack: (() -> Void)?

  @ObservedObject private var appNavigation = AppNavigationModel.shared
  @Environment(\.presentationMode) private var presentationMode

  var body: some View {
    VStack(spacing: 0) {
      Spacer().frame(height: safeAreaTop + 1).background(Color.white)
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
            Circle()
              .fill(Color.black.opacity(0.001))
              .frame(width: 44, height: 44)
            Image(systemName: "chevron.left")
              .font(.system(size: 20, weight: .semibold))
              .foregroundColor(Color(hex: "0x111111"))
          }
        }
        .buttonStyle(.plain)

        Text(title)
          .font(.system(size: 18, weight: .bold))
          .foregroundColor(Color(hex: "0x111111"))

        Spacer()

        trailing
      }
      .padding(.horizontal, 16)
      .padding(.top, 12)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Color.white)
    }
    .frame(maxWidth: .infinity, alignment: .topLeading)
    .background(Color.white)
    .ignoresSafeArea(edges: .top)
  }
}
