import SwiftUI

struct CheckoutView: View {
  let planName: String
  let price: String

  @State private var paymentMethod = "alipay"
  @State private var isProcessing = false
  @State private var isSuccess = false

  var body: some View {
    ZStack {
      Color.white.ignoresSafeArea()

      VStack(spacing: 0) {
        NavHeader(title: "支付收银台")

        VStack(spacing: 34) {
          VStack(spacing: 20) {
            HStack {
              Text("订单内容")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black.opacity(0.30))
              Spacer()
              Text(planName)
                .font(.system(size: 16, weight: .black))
            }
            HStack(alignment: .firstTextBaseline) {
              Text("应付金额")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black.opacity(0.30))
              Spacer()
              Text(price)
                .font(.system(size: 34, weight: .black))
                .foregroundColor(Color(hex: "#8B5CF6"))
            }
          }
          .padding(.top, 30)

          VStack(alignment: .leading, spacing: 12) {
            Text("选择支付方式")
              .font(.system(size: 12, weight: .black))
              .foregroundColor(.black.opacity(0.20))
            PaymentMethodRow(title: "支付宝支付", subtitle: "推荐已认证用户使用", symbol: "creditcard.fill", color: Color(hex: "#108EE9"), isSelected: paymentMethod == "alipay") {
              paymentMethod = "alipay"
            }
            PaymentMethodRow(title: "微信支付", subtitle: "极速安全支付体验", symbol: "message.fill", color: Color(hex: "#07C160"), isSelected: paymentMethod == "wechat") {
              paymentMethod = "wechat"
            }
          }

          Spacer()

          Button(action: pay) {
            HStack(spacing: 8) {
              if isProcessing {
                ProgressView().tint(.white)
              } else if isSuccess {
                Image(systemName: "checkmark")
                Text("支付成功")
              } else {
                Text("确认支付 \(price)")
              }
            }
            .font(.system(size: 17, weight: .black))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(isSuccess ? Color(hex: "#07C160") : Color(hex: "#8B5CF6"))
            .clipShape(Capsule())
          }
          .buttonStyle(.plain)
          .disabled(isProcessing || isSuccess)
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 34)
      }

      if isSuccess {
        VStack(spacing: 16) {
          Circle()
            .fill(Color(hex: "#07C160"))
            .frame(width: 96, height: 96)
            .overlay(Image(systemName: "checkmark").font(.system(size: 42, weight: .black)).foregroundColor(.white))
          Text("开通成功")
            .font(.system(size: 24, weight: .black))
          Text("现在开启您的 Pro 全能记忆体验")
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.black.opacity(0.40))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
      }
    }
  }

  private func pay() {
    isProcessing = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
      isProcessing = false
      isSuccess = true
    }
  }
}
