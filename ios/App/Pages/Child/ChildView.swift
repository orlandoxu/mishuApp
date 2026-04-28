import SwiftUI

struct ChildView: View {
  var body: some View {
    ZStack(alignment: .top) {
      Color(hex: "#F2F2F7").ignoresSafeArea()

      VStack(spacing: 0) {
        NavHeader(title: "")
        ScrollView(showsIndicators: false) {
          VStack(spacing: 18) {
            ChildIdentitySection()
            GrowthMilestonesSection()
            ChildFootprintsSection()
          }
          .padding(.horizontal, 20)
          .padding(.top, 8)
          .padding(.bottom, 38)
        }
      }
    }
  }
}
