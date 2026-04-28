import SwiftUI

struct PartnerView: View {
  var body: some View {
    ZStack(alignment: .top) {
      Color(hex: "#F2F2F7").ignoresSafeArea()

      ScrollView(showsIndicators: false) {
        VStack(spacing: 0) {
          PartnerIdentitySection()
          PartnerTimelineSection()
        }
        .padding(.top, 40)
        .padding(.bottom, 32)
      }

      NavHeader(title: "")
    }
  }
}
