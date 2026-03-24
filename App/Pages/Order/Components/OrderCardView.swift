import SwiftUI

struct OrderCardView: View {
  let order: OrderModel

  var isGray: Bool {
    order.isExpired
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(order.packageTitle)
        .font(.system(size: 16, weight: .bold))
        .foregroundColor(Color(hex: isGray ? "0x999999" : "0x111111"))

      HStack(alignment: .top, spacing: 0) {
        let deviceServiceMonths = calculateServiceMonths(from: order.deviceResource)
        if deviceServiceMonths > 0 {
          ResourceItemView(
            icon: "icon_order_basic",
            value: "\(deviceServiceMonths)个月",
            label: "基础服务",
            isGray: isGray
          )
        }

        if order.spaceCycleResource.total > 0 {
          ResourceItemView(
            icon: "icon_order_cloud",
            value: formatSpaceCycleDays(order.spaceCycleResource.total),
            label: "云存储",
            isGray: isGray
          )
        }

        if order.flowResource.total > 0 {
          ResourceItemView(
            icon: "icon_order_sim",
            value: formatFlow(order.flowResource.total),
            label: "sim流量",
            isGray: isGray
          )
        }

        if order.liveResource.total > 0 {
          ResourceItemView(
            icon: "icon_order_live",
            value: formatLive(order.liveResource.total),
            label: "远程直播",
            isGray: isGray
          )
        }

        Spacer()
      }

      HStack(alignment: .bottom) {
        HStack(alignment: .bottom, spacing: 4) {
          Text("¥ \(formatPrice(order.price))")
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(Color(hex: isGray ? "0x999999" : "0x111111"))

          if order.originalPrice > 0 {
            Text("¥\(formatPrice(order.originalPrice))")
              .font(.system(size: 12))
              .foregroundColor(Color(hex: "0x999999"))
              .strikethrough()
          }
        }

        Spacer()
        Text(formatDate(order.startTime))
          .font(.system(size: 12))
          .foregroundColor(Color(hex: "0x999999"))
      }
    }
    .padding(16)
    .background(Color.white)
    .cornerRadius(12)
  }

  /// 暂时先注销了，下个版本开发
  // private var detailBtn: some View {
  //     Button {
  //     } label: {
  //       Text("查看详情")
  //         .font(.system(size: 14, weight: .medium))
  //         .foregroundColor(Color(hex: "0x06BAFF"))
  //         .padding(.horizontal, 20)
  //         .frame(height: 32)
  //         .overlay(
  //           RoundedRectangle(cornerRadius: 16)
  //             .stroke(Color(hex: "0x06BAFF"), lineWidth: 1)
  //         )
  //     }
  // }

  func formatPrice(_ price: Int64) -> String {
    String(format: "%.2f", Double(price) / 100.0).dropTailZero + "元"
  }

  func formatDate(_ timestamp: Int64) -> String {
    let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000)
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy/MM/dd HH:mm"
    return formatter.string(from: date)
  }

  func formatSpaceCycleDays(_ days: Int64) -> String {
    "\(days)天"
  }

  /// 根据设备服务资源的起止时间计算月份，按 30 天/月并四舍五入取整
  func calculateServiceMonths(from resource: OrderResourceModel) -> Int {
    guard resource.endTime > resource.startTime else { return 0 }
    let monthMilliseconds = 30.4 * 24.0 * 60.0 * 60.0 * 1000.0
    let durationMilliseconds = Double(resource.endTime - resource.startTime)
    let rawMonths = durationMilliseconds / monthMilliseconds
    return max(0, Int(rawMonths.rounded()))
  }

  func formatFlow(_ bytes: Int64) -> String {
    let gb = Double(bytes) / 1024 / 1024 / 1024
    if gb >= 1 {
      return String(format: "%.0fGB/月", gb)
    }
    let mb = Double(bytes) / 1024 / 1024
    return String(format: "%.0fMB", mb)
  }

  func formatLive(_ value: Int64) -> String {
    "\(value)分钟"
  }
}

struct ResourceItemView: View {
  let icon: String
  let value: String
  let label: String
  let isGray: Bool

  var body: some View {
    VStack(spacing: 8) {
      Image(icon)
        .resizable()
        .scaledToFit()
        .frame(width: 24, height: 24)
        .foregroundColor(isGray ? Color(hex: "0x999999") : Color(hex: "0x06BAFF"))

      VStack(spacing: 4) {
        Text(value)
          .font(.system(size: 14, weight: .bold))
          .foregroundColor(Color(hex: isGray ? "0x999999" : "0x111111"))
          .lineLimit(1)
          .minimumScaleFactor(0.8)

        Text(label)
          .font(.system(size: 11))
          .foregroundColor(Color(hex: "0x999999"))
      }
    }
    .frame(width: 80)
    .padding(.vertical, 8)
    .background(Color(hex: "0xF8F8F8"))
    .cornerRadius(8)
    .padding(.trailing, 8)
  }
}
