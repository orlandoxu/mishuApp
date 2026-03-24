import SwiftUI

// 产品上暂时不显示这部分，有点太占空间了
// struct StatusBarView: View {
//   let statusText: String
//   let timeText: String
//   let gpsText: String
//   let voltageText: String

//   var body: some View {
//     HStack(spacing: 0) {
//       HStack(spacing: 4) {
//         Circle().fill(Color.green).frame(width: 8, height: 8)
//         Text(statusText)
//           .font(.system(size: 13))
//           .foregroundColor(.white)
//       }
//       .frame(maxWidth: .infinity)

//       HStack(spacing: 4) {
//         Image("icon_live_time")
//           .renderingMode(.template)
//           .resizable()
//           .frame(width: 14, height: 14)
//           .foregroundColor(.white)
//         Text(timeText)
//           .font(.system(size: 13))
//           .foregroundColor(.white)
//       }
//       .frame(maxWidth: .infinity)

//       HStack(spacing: 4) {
//         Image("icon_live_gps")
//           .renderingMode(.template)
//           .resizable()
//           .frame(width: 14, height: 14)
//           .foregroundColor(.white)
//         Text(gpsText)
//           .font(.system(size: 13))
//           .foregroundColor(.white)
//       }
//       .frame(maxWidth: .infinity)

//       HStack(spacing: 4) {
//         Image("icon_live_voltage")
//           .renderingMode(.template)
//           .resizable()
//           .frame(width: 14, height: 14)
//           .foregroundColor(.white)
//         Text(voltageText)
//           .font(.system(size: 13))
//           .foregroundColor(.white)
//       }
//       .frame(maxWidth: .infinity)
//     }
//     .frame(height: 40)
//     .background(Color(hex: "0x111111"))
//   }
// }
