import SwiftUI
import UIKit

struct ActiveLandingView: View {
  let imei: String
  let entry: ActiveLandingEntry

  @ObservedObject private var appNavigation = AppNavigationModel.shared
  @StateObject private var viewModel: ActiveLandingViewModel
  @State private var currentPage: Int = 0

  init(imei: String, entry: ActiveLandingEntry) {
    self.imei = imei
    self.entry = entry
    _viewModel = StateObject(wrappedValue: ActiveLandingViewModel(imei: imei))
  }

  var body: some View {
    VStack(spacing: 0) {
      NavHeader(title: "设备激活")

      PageViewController(
        pages: pageControllers,
        currentPage: $currentPage,
        isUserInteractionEnabled: false
      )
      .frame(maxWidth: .infinity, maxHeight: .infinity)

      bottomButton
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, safeAreaBottom + 12)
    }
    .ignoresSafeArea()
    .background(Color.white.ignoresSafeArea())
  }

  private var pageControllers: [UIViewController] {
    [
      UIHostingController(rootView: ActiveLandingIntroPage()),
      UIHostingController(rootView: ActiveLandingSuccessPage(play: currentPage == 1)),
    ]
  }

  private var bottomButton: some View {
    Button {
      handleBottomAction()
    } label: {
      Text(buttonTitle)
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .background(Color(hex: "0x06BAFF"))
        .cornerRadius(24)
    }
    .buttonStyle(.plain)
    .disabled(viewModel.isActivating)
  }

  private var buttonTitle: String {
    if currentPage == 0 {
      return viewModel.isActivating ? "设备激活中..." : "立即激活设备"
    }
    return "立即去体验"
  }

  private func handleBottomAction() {
    if currentPage == 0 {
      Task {
        let activated = await viewModel.activateDevice()
        guard activated else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
          currentPage = 1
        }
      }
      return
    }

    switch entry {
    case .cloudService:
      appNavigation.replaceTop(with: .cloudBenefits(imei: imei))
    case .vehicleLive:
      appNavigation.replaceTop(with: .vehicleLive(deviceId: imei))
    }
  }
}
