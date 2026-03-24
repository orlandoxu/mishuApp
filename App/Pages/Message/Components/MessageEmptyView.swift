import SwiftUI

struct MessageEmptyView: View {
  let title: String

  var body: some View {
    VStack(spacing: 16) {
      Image("img_message_empty")
        .resizable()
        .scaledToFit()
        .frame(width: 200, height: 200)

      Text(title)
        .font(.system(size: 14))
        .foregroundColor(Color(hex: "0x999999"))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.white)
  }
}
