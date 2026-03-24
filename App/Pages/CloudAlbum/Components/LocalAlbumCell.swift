import SwiftUI

struct LocalAlbumCell: View {
  let count: Int

  var body: some View {
    VStack(spacing: 12) {
      Image("icon_album_local")
        .resizable()
        .scaledToFit()
        .frame(width: 36, height: 36)

      VStack(spacing: 4) {
        Text("本地相册")
          .font(.system(size: 18, weight: .semibold))
          .foregroundColor(.white)

        Text("共\(count)个")
          .font(.system(size: 14))
          .foregroundColor(.white.opacity(0.8))
      }
    }
    .frame(maxWidth: .infinity)
    .frame(height: 166, alignment: .center)
    .background(
      LinearGradient(
        gradient: Gradient(colors: [Color(hex: "0x00B0FF"), Color(hex: "0x0091EA")]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    )
    .cornerRadius(12)
  }
}
