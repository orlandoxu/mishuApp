import SwiftUI

struct NavHeader<Trailing: View>: View {
  let title: String
  let trailing: Trailing
  let onBack: (() -> Void)?

  @ObservedObject private var appNavigation = AppNavigationModel.shared
  @Environment(\.presentationMode) private var presentationMode

  init(title: String, onBack: (() -> Void)? = nil, @ViewBuilder trailing: () -> Trailing) {
    self.title = title
    self.onBack = onBack
    self.trailing = trailing()
  }

  init(title: String, onBack: (() -> Void)? = nil) where Trailing == EmptyView {
    self.title = title
    self.onBack = onBack
    trailing = EmptyView()
  }

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
