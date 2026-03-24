import SwiftUI

struct WifiBindingNoticeView: View {
  let onNext: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      NavHeader(title: "Wifi绑定") {
        Text("Step 1")
          .font(.system(size: 14))
          .foregroundColor(Color(hex: "0x999999"))
      }

      VStack(spacing: 0) {
        Text("请启动车辆")
          .font(.system(size: 18, weight: .medium))
          .foregroundColor(Color(hex: "0x333333"))
          .padding(.top, 32)

        Text("请确保车辆处于启动状态，以便记录仪正常工作")
          .font(.system(size: 14))
          .foregroundColor(Color(hex: "0x666666"))
          .padding(.top, 8)
          .padding(.horizontal, 32)
          .multilineTextAlignment(.center)

        Spacer()

        Image("img_start_engine").frame(maxWidth: .infinity)

        Spacer()

        Button {
          onNext()
        } label: {
          Text("下一步")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color(hex: "0x28C4FB"))
            .cornerRadius(24)
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 40)
      }
    }
    .ignoresSafeArea()
    .navigationBarHidden(true)
  }
}
