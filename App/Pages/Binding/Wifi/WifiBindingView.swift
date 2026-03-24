import SwiftUI

struct WifiBindingView: View {
  @State private var currentStep = 1

  var body: some View {
    ZStack {
      if currentStep == 1 {
        WifiBindingNoticeView(onNext: {
          currentStep = 2
        })
      } else {
        WifiBindingConnectionView()
      }
    }
    .ignoresSafeArea()
    .navigationBarHidden(true)
  }
}
