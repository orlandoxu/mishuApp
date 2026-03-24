import SwiftUI

struct ServiceRightItem: Identifiable {
  let id = UUID()
  let icon: String
  let title: String
  let desc: String
}

enum ServiceRightsCatalog {
  static let baseServices: [ServiceRightItem] = [
    ServiceRightItem(icon: "icon_base_travel", title: "行程报告", desc: "每次行车后，自动生成行程报告"),
    ServiceRightItem(icon: "icon_base_park_monitor", title: "停车监控", desc: "停车后，依然可以开启监控模式"),
    ServiceRightItem(icon: "icon_base_crash", title: "AI碰撞分析", desc: "AI分析是否有碰撞发生"),
    ServiceRightItem(icon: "icon_base_snapshot", title: "手机抓拍", desc: "可远程去抓拍图片和视频"),
    ServiceRightItem(icon: "icon_base_snapshot_voice", title: "语音抓拍", desc: "通过语音，抓拍图片和视频"),
    ServiceRightItem(icon: "icon_base_playback", title: "轨迹回放", desc: "生成历史的回放动画"),
    ServiceRightItem(icon: "icon_base_analysis", title: "驾驶分析", desc: "智能评估驾驶员的驾驶行为"),
    ServiceRightItem(icon: "icon_base_album", title: "云相册", desc: "提供云端视频图片，行程报告存储"),
    ServiceRightItem(icon: "icon_base_position", title: "远程定位", desc: "手机实时查看车辆位置"),
    // ServiceRightItem(icon: "icon_base_record", title: "云记录", desc: "30分钟云记录免费赠送"),
  ]

  static let guardServices: [ServiceRightItem] = [
    ServiceRightItem(icon: "icon_obd_fast", title: "汽车快速检测", desc: "快速检测发动机OBD，即时掌握车况"),
    ServiceRightItem(icon: "icon_obd_deep", title: "全车深度检测", desc: "10次/月：全车深度 + 数据流专业报告"),
    ServiceRightItem(icon: "icon_obd_clean", title: "故障码清除", desc: "清除原车历史故障码，软件故障码"),
    ServiceRightItem(icon: "icon_obd_audit", title: "年检预审", desc: "提前预检不白跑（仅供参考）"),
    ServiceRightItem(icon: "icon_obd_monitor", title: "车辆实时监听", desc: "故障提前预警（需车辆支持）"),
    ServiceRightItem(icon: "icon_obd_battery", title: "电池保护分析", desc: "电池自动分析，异常预警（仅供参考）"),
    ServiceRightItem(icon: "icon_obd_ai", title: "AI汽修大师", desc: "30年专家经验 + AI大数据，养修全能顾问"),
    ServiceRightItem(icon: "icon_obd_plate", title: "抄牌提醒", desc: "AI违停预警，防抄牌/防贴条"),
  ]
}

struct ServiceRightsModal: View {
  let title: String
  let items: [ServiceRightItem]
  let onClose: () -> Void

  @State private var currentPage = 0

  var body: some View {
    VStack(spacing: 0) {
      // Title Bar
      HStack {
        Text(title)
          .font(.system(size: 18, weight: .bold))
          .foregroundColor(Color(hex: "0x111111"))
        Spacer()
        Button {
          onClose()
        } label: {
          Image(systemName: "xmark")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(Color(hex: "0x999999"))
            .frame(width: 44, height: 44)
            .background(Color(hex: "0xF5F6F7"))
            .clipShape(Circle())
        }
      }
      .padding(.horizontal, 20)
      .padding(.top, 24)
      .padding(.bottom, 10)

      // Carousel
      TabView(selection: $currentPage) {
        ForEach(0 ..< items.count, id: \.self) { index in
          ServiceRightCard(item: items[index])
            .tag(index)
        }
      }
      .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
      .frame(height: 320)

      // Page Indicator
      HStack(spacing: 6) {
        ForEach(0 ..< items.count, id: \.self) { index in
          Circle()
            .fill(currentPage == index ? Color(hex: "0x06BAFF") : Color(hex: "0xE0E0E0"))
            .frame(width: 6, height: 6)
        }
      }
      .padding(.bottom, 24)

      // Confirmation Button
      Button { onClose() } label: {
        Text("我知道了").FullBrandButton()
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 20 + safeAreaBottom)
    }
    .frame(maxWidth: .infinity, alignment: .top)
    .background(Color.white)
    .cornerRadius(24, corners: [.topLeft, .topRight])
  }
}

private struct ServiceRightCard: View {
  let item: ServiceRightItem

  var body: some View {
    VStack(spacing: 24) {
      Spacer()

      ZStack {
        Circle()
          .fill(Color(hex: "0xF0F9FF"))
          .frame(width: 88, height: 88)

        Image(item.icon)
          .resizable()
          .scaledToFit()
          .frame(width: 48, height: 48)
      }

      VStack(spacing: 12) {
        Text(item.title)
          .font(.system(size: 20, weight: .bold))
          .foregroundColor(Color(hex: "0x111111"))

        Text(item.desc)
          .font(.system(size: 14))
          .foregroundColor(Color(hex: "0x666666"))
          .multilineTextAlignment(.center)
          .lineLimit(2)
          .padding(.horizontal, 16)
      }

      Spacer()
    }
    .frame(maxWidth: .infinity)
    .background(Color.white)
    .cornerRadius(12)
    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    .padding(.horizontal, 20)
    .padding(.vertical, 10)
  }
}
