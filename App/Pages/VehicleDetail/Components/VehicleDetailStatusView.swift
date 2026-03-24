import Kingfisher
import SwiftUI

struct VehicleDetailStatusView: View {
  let vehicle: VehicleModel

  var body: some View {
    VStack(spacing: 16) {
      // Status & Tip
      VStack(spacing: 8) {
        StatusBadge(
          text: vehicle.onlineStatusText,
          dotColor: statusDotColor(onlineStatus: vehicle.onlineStatus)
        )

        // TODO: 下个版本这儿要做OBD需求
        // Text("连接Wi-Fi进行一次基础检测吧")
        //   .font(.system(size: 16))
        //   .foregroundColor(Color(hex: "0x999999"))
      }
      .padding(.top, 20)

      // Car Image
      if let urlStr = vehicle.car?.markImgUrl, let url = URL(string: urlStr) {
        KFImage(url)
          .resizable()
          .scaledToFit()
          .frame(height: 120)
          .padding(.top, 30)
      } else {
        Image(systemName: "car.fill") // Placeholder
          .resizable()
          .scaledToFit()
          .frame(height: 120)
          .foregroundColor(.gray.opacity(0.3))
      }

      // btnObdCheck // 先不要删除，后续开发

      // Speed
      Group {
        if vehicle.onlineStatus == 1 {
          HStack(alignment: .lastTextBaseline, spacing: 2) {
            Text("\(vehicle.gps?.speed ?? 0)")
              .font(.system(size: 24, weight: .bold))
              .foregroundColor(Color(hex: "0x333333"))
            Text("Km/h")
              .font(.system(size: 14))
              .foregroundColor(Color(hex: "0x999999"))
          }
        } else {
          Text("未点火")
            .font(.system(size: 20, weight: .medium))
            .foregroundColor(Color(hex: "0x333333"))
        }
      }
      .padding(.bottom, 20)
    }
    .frame(maxWidth: .infinity)
  }

  private func statusDotColor(onlineStatus: Int) -> Color {
    if onlineStatus == 1 { return Color(hex: "0x11C06A") }
    if onlineStatus == 2 { return Color(hex: "0xFF8A00") }
    if onlineStatus == 7 { return Color(hex: "0x06BAFF") }
    return Color(hex: "0xD8D8D8")
  }

  private var btnObdCheck: some View {
    Button {
      ToastCenter.shared.show("功能开发中")
    } label: {
      Text("快速检测")
        .font(.system(size: 14, weight: .medium))
        .foregroundColor(.white)
        .padding(.horizontal, 32)
        .padding(.vertical, 10)
        .background(Color(hex: "0x06BAFF"))
        .cornerRadius(20)
        .shadow(color: Color(hex: "0x06BAFF").opacity(0.3), radius: 4, x: 0, y: 2)
    }
  }
}

private struct StatusBadge: View {
  let text: String
  let dotColor: Color

  var body: some View {
    HStack(spacing: 6) {
      Circle()
        .fill(dotColor)
        .frame(width: 6, height: 6)

      Text(text)
        .font(.system(size: 16, weight: .semibold))
        .foregroundColor(Color(hex: "0x333333"))
        .frame(minWidth: 60, alignment: .center)
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 8)
    .background(Color.white)
    .cornerRadius(10)
  }
}
