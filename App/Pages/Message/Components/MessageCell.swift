import SwiftUI
import Kingfisher

struct MessageCell: View {
  let message: MessageModel
  let time: String
  let hasUnread: Bool
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(message.title)
          .font(.system(size: 16, weight: .medium))
          .foregroundColor(Color(hex: "0x111111"))
        
        Spacer()
        
        if hasUnread {
          Circle()
            .fill(Color.red)
            .frame(width: 6, height: 6)
        }
      }

      if message.mediaKind != .none {
        MessageCellMediaPreview(
          kind: message.mediaKind,
          thumbnailUrl: message.mediaThumbnailUrl
        )
      }
      
      HStack {
        Text(time)
          .font(.system(size: 12))
          .foregroundColor(Color(hex: "0x999999"))
        
        Spacer()
        
        HStack(spacing: 2) {
          Text("更多")
            .font(.system(size: 12))
          Image(systemName: "chevron.right")
            .font(.system(size: 10))
        }
        .foregroundColor(Color(hex: "0x999999"))
      }
    }
    .padding(16)
    .background(Color.white)
    .cornerRadius(8)
    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
  }
}

private struct MessageCellMediaPreview: View {
  let kind: MessageModel.MediaKind
  let thumbnailUrl: String

  var body: some View {
    ZStack {
      if let url = URL(string: thumbnailUrl), !thumbnailUrl.isEmpty {
        KFImage(url)
          .resizable()
          .placeholder {
            RoundedRectangle(cornerRadius: 6)
              .fill(Color.gray.opacity(0.2))
          }
          .scaledToFill()
      } else {
        RoundedRectangle(cornerRadius: 6)
          .fill(Color.gray.opacity(0.2))
          .overlay(
            Image(systemName: kind == .video ? "video.fill" : "photo.fill")
              .foregroundColor(.gray)
          )
      }

      if kind == .video {
        Image(systemName: "play.circle.fill")
          .font(.system(size: 28))
          .foregroundColor(.white.opacity(0.9))
          .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
      }
    }
    .frame(height: 160)
    .clipShape(RoundedRectangle(cornerRadius: 6))
  }
}
