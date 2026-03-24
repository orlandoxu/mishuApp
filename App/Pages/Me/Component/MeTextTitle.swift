import SwiftUI

struct MeTextTitle: View {
  var title: String

  var body: some View {
    Text(title)
      .frame(maxWidth: .infinity, alignment: .leading)
      .font(.system(size: 18, weight: .medium))
      .foregroundColor(Color(hex: "0x333333"))
      .padding(.top, 24)
      .padding(.horizontal, 16)
  }
}
