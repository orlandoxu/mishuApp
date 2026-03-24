import Kingfisher
import SwiftUI

struct ListItemCell: View {
  let asset: AlbumAsset
  let onTapMap: () -> Void
  @ObservedObject private var appNavigation: AppNavigationModel = .shared

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // header
      HStack {
        Text(CloudAlbumType.title(for: asset.type))
          .font(.system(size: 16, weight: .medium))
          .foregroundColor(Color(hex: "0x333333"))

        Spacer()

        Button(action: onTapMap) {
          HStack(spacing: 2) {
            Text("地图")
              .font(.system(size: 14))
            Image(systemName: "chevron.right")
              .font(.system(size: 10))
          }
          .foregroundColor(Color(hex: "0x0091EA"))
        }
      }

      // Time
      Text(formatTime(asset.createTime))
        .font(.system(size: 12))
        .foregroundColor(Color(hex: "0x999999"))

      // Media Preview
      AssetCell(asset: asset) {
        appNavigation.push(.cloudAlbumAssetDetail(asset: asset))
      }
      .frame(width: windowWidth * 0.55)
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color.white)
    )
  }

  private func formatTime(_ timestamp: Int64) -> String {
    let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000)
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return formatter.string(from: date)
  }
}
