import Kingfisher
import SwiftUI

struct MeHeaderView: View {
  private let appNavigation = AppNavigationModel.shared

  @ObservedObject private var selfStore: SelfStore = .shared

  var body: some View {
    ZStack(alignment: .top) {
      // 背景：使用统一的背景组件
      VStack(spacing: 0) {
        // 用户信息行
        userInfoRow
          .padding(.top, safeAreaTop + 32)
          .padding(.horizontal, 24)

        // 统计数据行
        statsRow
          .padding(.top, 24)
          .padding(.bottom, 20)
      }
    }
  }

  private var userInfoRow: some View {
    HStack(spacing: 16) {
      UserAvatar(size: 64, avatar: selfStore.selfUser?.headImg)

      VStack(alignment: .leading, spacing: 4) {
        Text(displayName)
          .font(.system(size: 20, weight: .bold))
          .foregroundColor(Color(hex: "0x111111"))

        Text(selfStore.selfUser?.mobile ?? "-")
          .font(.system(size: 14, weight: .regular))
          .foregroundColor(Color(hex: "0x666666"))
      }

      Spacer(minLength: 0)

      Image("icon_me_more_arrow_big")
        .resizable()
        .scaledToFit()
        .frame(width: 20, height: 20)
        .foregroundColor(Color(hex: "0xCCCCCC"))
    }
    .contentShape(Rectangle())
    .onTapGesture {
      appNavigation.push(.userInfoEdit)
    }
  }

  private var statsRow: some View {
    HStack(spacing: 0) {
      // 距离
      statItem(
        value: String(format: "%.1f", Double(selfStore.selfUser?.totalMiles ?? 0)).dropTailZero,
        unit: "km",
        icon: "icon_me_miles",
        title: "总里程"
      )

      // 行车时长
      statItem(
        value: String(format: "%.1f", Double(selfStore.selfUser?.totalTimeUsing ?? 0) / 3600.0).dropTailZero,
        unit: "小时",
        icon: "icon_me_time",
        title: "总时长"
      )

      // 平均速度
      statItem(
        value: String(format: "%.1f", selfStore.selfUser?.avgSpeed ?? 0).dropTailZero,
        unit: "km/h",
        icon: "icon_me_avg",
        title: "平均速度"
      )
    }
  }

  private func statItem(value: String, unit: String, icon: String, title: String) -> some View {
    VStack(spacing: 8) {
      // 数值 + 单位
      HStack(alignment: .lastTextBaseline, spacing: 2) {
        Text(value)
          .font(.system(size: 24, weight: .bold)) // 字体加大
          .foregroundColor(Color(hex: "0x111111"))

        if !unit.isEmpty {
          Text(unit)
            .font(.system(size: 14, weight: .bold)) // 单位小一点
            .foregroundColor(Color(hex: "0x111111"))
        }
      }

      // 图标 + 标题
      HStack(spacing: 4) {
        Image(icon)
          .resizable()
          .scaledToFit()
          .frame(width: 14, height: 14)

        Text(title)
          .font(.system(size: 12, weight: .regular))
          .foregroundColor(Color(hex: "0x666666"))
      }
    }
    .frame(maxWidth: .infinity)
  }

  private var displayName: String {
    let value = (selfStore.selfUser?.nickname ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    return value.isEmpty ? "未设置昵称" : value
  }
}
