import SwiftUI

struct AlbumCell: View {
  let type: CloudAlbumType
  let count: Int

  var body: some View {
    VStack(spacing: 0) {
      Spacer(minLength: 0)

      Image(type.icon)
        .resizable()
        .scaledToFit()
        .frame(width: 36, height: 36)

      Text(type.title)
        .font(.system(size: 18, weight: .medium))
        .foregroundColor(Color(hex: "0x333333"))
        .padding(.top, 10)

      if count > 0 {
        Text("今日+\(count)")
          .font(.system(size: 14, weight: .medium))
          .foregroundColor(Color(hex: "0x0091EA"))
          .padding(.horizontal, 8)
          .padding(.vertical, 2)
          .background(Color(hex: "0xE1F5FE"))
          .cornerRadius(10)
          .padding(.top, 10)
      }

      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity)
    .frame(height: 166, alignment: .center)
    .background(Color.white)
    .cornerRadius(12)
  }
}
