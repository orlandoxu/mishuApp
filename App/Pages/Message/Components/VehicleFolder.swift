import Kingfisher
import SwiftUI

// MARK: - VehicleFolder

/// 车辆消息文件夹视图
/// 展示车辆图标、标题、最新消息内容、时间和未读状态
struct VehicleFolder: View {
  // MARK: - Properties

  /// 车辆图标 URL
  let imageUrl: String

  /// 标题（车牌号或设备昵称）
  let title: String

  /// 最新消息内容
  let content: String

  /// 时间文本
  let time: String

  /// 是否有未读消息
  let hasUnread: Bool

  // MARK: - Body

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      // 车辆图标
      if let url = URL(string: imageUrl), !imageUrl.isEmpty {
        KFImage(url)
          .resizable()
          .scaledToFit()
          .frame(width: 100, height: 74)
          .background(Color(hex: "0xF5F5F5"))
          .clipShape(RoundedRectangle(cornerRadius: 4))
      } else {
        RoundedRectangle(cornerRadius: 4)
          .fill(Color(hex: "0xF5F5F5"))
          .frame(width: 100, height: 74)
          .overlay(
            Image(systemName: "car.fill")
              .foregroundColor(ThemeColor.gray300)
              .font(.system(size: 24))
          )
      }

      // 右侧内容区
      VStack(alignment: .leading, spacing: 6) {
        // 标题行（带未读红点）
        HStack {
          Text(title)
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(Color(hex: "0x333333"))

          Spacer()
        }

        // 最新消息内容
        Text(content)
          .font(.system(size: 14))
          .foregroundColor(Color(hex: "0x333333"))
          .lineLimit(1)

        // 底部行：时间 + 更多
        HStack {
          Text(time)
            .font(.system(size: 13))
            .foregroundColor(Color(hex: "0x999999"))

          Spacer()

          HStack(spacing: 2) {
            Text("更多")
              .font(.system(size: 13))
            Image(systemName: "chevron.right")
              .font(.system(size: 10))
          }
          .foregroundColor(Color(hex: "0x999999"))
        }
        .padding(.top, 8)
      }
    }
    .padding(12)
    .background(Color.white)
    .unreadBadge(hasUnread)
    .cornerRadius(8)
    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
  }
}
