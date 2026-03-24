import Kingfisher
import SwiftUI

struct UserAvatar: View {
  let size: CGFloat
  let avatar: String?

  var body: some View {
    Group {
      if let urlString = avatar,
         let url = URL(string: urlString), !urlString.isEmpty
      {
        KFImage(url)
          .resizable()
          .frame(width: size, height: size)
          .scaledToFill()
          .clipShape(Circle())
      } else {
        // 使用默认头像 img_default_avatar
        Image("img_default_avatar")
          .resizable()
          .frame(width: size, height: size)
          .scaledToFit()
          .foregroundColor(Color(hex: "0xCCCCCC"))
          .background(Color(hex: "0xF5F5F5"))
          .clipShape(Circle())
      }
    }
  }
}
