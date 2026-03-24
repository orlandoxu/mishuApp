import SwiftUI
import UIKit

struct WifiDirectView: View {
  @StateObject private var viewModel: WifiDirectViewModel
  @State private var currentPage: Int = 0

  init(imei: String) {
    _viewModel = StateObject(wrappedValue: WifiDirectViewModel(imei: imei))
  }

  var body: some View {
    VStack(spacing: 0) {
      NavHeader(title: "WIFI直连")

      PageViewController(
        pages: pageControllers,
        currentPage: $currentPage,
        isUserInteractionEnabled: false
      )
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .onAppear {
        currentPage = viewModel.stage.index
        viewModel.onAppear()
      }
      .onChange(of: viewModel.stage) { newStage in
        withAnimation(.easeInOut(duration: 0.3)) {
          currentPage = newStage.index
        }
      }
      .onDisappear {
        viewModel.onDisappear()
      }
    }
    .background(Color(hex: "0xF3F4F6").ignoresSafeArea())
  }

  private var pageControllers: [UIViewController] {
    [
      UIHostingController(
        rootView: WifiDirectIgnitionPage {
          viewModel.startDirectConnect()
        }
      ),
      UIHostingController(
        rootView: WifiDirectOpeningPage {
          viewModel.cancelAndBack()
        }
      ),
      UIHostingController(
        rootView: WifiDirectConnectingPage {
          viewModel.cancelAndBack()
        }
      ),
      UIHostingController(
        rootView: WifiDirectFailurePage(
          reason: failureReason,
          imei: viewModel.imei,
          onRetryOpen: {
            viewModel.startDirectConnect()
          },
          onOpenWifiSettings: {
            viewModel.openWifiSettings()
          }
        )
      ),
      UIHostingController(
        rootView: WifiDirectSuccessPage(imei: viewModel.imei)
      ),
    ]
  }

  private var failureReason: WifiDirectViewModel.FailureReason {
    if case let .failed(reason) = viewModel.stage {
      return reason
    }
    return .openFailed
  }
}
