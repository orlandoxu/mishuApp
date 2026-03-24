import Kingfisher
import SwiftUI

struct MessageItem: View {
  let message: MessageModel
  let time: String
  let hasUnread: Bool
  let onTapMedia: (() -> Void)?

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      VStack(alignment: .leading, spacing: 8) {
        Text(message.title)
          .font(.system(size: 16, weight: .regular))
          .foregroundColor(Color(hex: "0x111111"))
          .lineLimit(2)
          .fixedSize(horizontal: false, vertical: true)

        Text(time)
          .font(.system(size: 12))
          .foregroundColor(Color(hex: "0x999999"))
      }

      Spacer()

      if message.mediaKind != .none, let url = URL(string: message.coverUrl), !message.coverUrl.isEmpty {
        ZStack(alignment: .topTrailing) {
          KFImage(url)
            .resizable()
            .placeholder {
              Color.gray.opacity(0.1)
            }
            .scaledToFill()
            .clipped()

          if message.mediaKind == .video {
            Image(systemName: "play.circle.fill")
              .font(.system(size: 24))
              .foregroundColor(.white.opacity(0.9))
              .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
              .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
              .allowsHitTesting(false)
          }
        }
        .frame(width: 100, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .contentShape(Rectangle())
        .onTapGesture {
          onTapMedia?()
        }
      }
    }
    .padding(16)
    .background(Color.white)
    .unreadBadge(hasUnread)
    .cornerRadius(8)
    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
  }
}
