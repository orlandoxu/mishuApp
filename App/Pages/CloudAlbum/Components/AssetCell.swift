import Kingfisher
import SwiftUI

struct AssetCell: View {
  var asset: AlbumAsset
  var isSelectedMode: Bool
  var isSelected: Bool
  var onTap: () -> Void

  init(asset: AlbumAsset, isSelectedMode: Bool = false, isSelected: Bool = false, onTap: @escaping () -> Void) {
    self.asset = asset
    self.isSelectedMode = isSelectedMode
    self.isSelected = isSelected
    self.onTap = onTap
  }

  var body: some View {
    GeometryReader { geo in
      ZStack(alignment: .topTrailing) {
        KFImage(URL(string: asset.urlThumb))
          .resizable()
          .scaledToFill()
          .frame(width: geo.size.width, height: geo.size.width * 9 / 16)
          .clipped()
          .cornerRadius(8)
          .contentShape(Rectangle())
          .onTapGesture {
            onTap()
          }

        // 视频图标
        if asset.mtype == 2 {
          Image(systemName: "play.circle.fill")
            .font(.system(size: 32))
            .foregroundColor(.white.opacity(0.8))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false)
        }

        // 前后摄标识 (左上角)
        Text(asset.camera == 1 ? "前摄" : "后摄") // 假设 1 是前摄
          .font(.system(size: 10))
          .foregroundColor(.white)
          .padding(.horizontal, 4)
          .padding(.vertical, 2)
          .background(Color.black.opacity(0.5))
          .cornerRadius(2)
          .padding(4)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

        // 时间 (右下角)
        Text(formatTime(asset.createTime))
          .font(.system(size: 12))
          .foregroundColor(.white)
          .padding(4)
          .shadow(color: .black, radius: 1)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)

        // 编辑模式选中状态 (右上角) - 与本地相册保持一致
        if isSelectedMode {
          Group {
            if isSelected {
              ZStack {
                Circle()
                  .fill(Color(hex: "0x06BAFF"))
                Image(systemName: "checkmark")
                  .font(.system(size: 11, weight: .semibold))
                  .foregroundColor(.white)
              }
            } else {
              Image(systemName: "circle")
                .foregroundColor(.white)
                .background(Circle().fill(Color.black.opacity(0.2)))
            }
          }
          .frame(width: 20, height: 20)
          .padding(8)
        }
      }
    }
    .frame(maxWidth: .infinity)
    .aspectRatio(16 / 9, contentMode: .fit)
  }

  private func formatTime(_ timestamp: Int64) -> String {
    let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000)
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    return formatter.string(from: date)
  }
}
