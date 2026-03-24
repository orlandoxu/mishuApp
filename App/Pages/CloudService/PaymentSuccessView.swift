import SwiftUI

struct PaymentSuccessView: View {
  @ObservedObject private var appNavigation = AppNavigationModel.shared

  var body: some View {
    VStack(spacing: 0) {
      NavHeader(title: "支付成功")

      ScrollView {
        VStack(spacing: 0) {
          Spacer().frame(height: 80)

          // 1. Success Icon
          Image(systemName: "checkmark.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 72, height: 72)
            .foregroundColor(Color(hex: "0x00C800")) // Green

          // 2. Success Text
          Text("付款成功")
            .font(.system(size: 20, weight: .medium))
            .foregroundColor(Color(hex: "0x333333"))
            .padding(.top, 24)

          Text("感谢您的使用")
            .font(.system(size: 16))
            .foregroundColor(Color(hex: "0x666666"))
            .padding(.top, 8)

          Spacer().frame(height: 120)

          // 3. Action Button
          Button {
            // Return to order list to view details
            appNavigation.popToRoot()
            appNavigation.replaceTop(with: .orderList)
          } label: {
            Text("查看订单详情")
              .font(.system(size: 16, weight: .medium))
              .foregroundColor(ThemeColor.brand500)
              .frame(width: 240, height: 48)
              .background(Color.white)
              .cornerRadius(8)
              .overlay(
                RoundedRectangle(cornerRadius: 8)
                  .stroke(ThemeColor.brand500, lineWidth: 1)
              )
          }

          Spacer()
        }
        .frame(maxWidth: .infinity)
      }
      .background(Color.white) // Changed to white as per screenshot (looks clean white)
    }
    .navigationBarHidden(true)
  }
}
