import SwiftUI
import WechatOpenSDK

struct CashierView: View {
  let package: PackageItem
  let imei: String
  @ObservedObject private var appNavigation = AppNavigationModel.shared
  @State private var isWeChatSelected: Bool = true
  @State private var isProcessing: Bool = false

  var body: some View {
    VStack(spacing: 0) {
      NavHeader(title: "支付订单")

      ScrollView {
        VStack(spacing: 16) {
          // Order Detail Card
          VStack(alignment: .leading, spacing: 12) {
            HStack {
              Text("订单详情:")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "0x333333"))
              Spacer()
              Text(package.displayTitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ThemeColor.brand500)
            }

            HStack {
              Text("订单金额:")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "0x333333"))
              Spacer()
              Text("¥\(package.displayPriceYuanString)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(ThemeColor.brand500)
            }
          }
          .padding(16)
          .background(Color.white)
          .cornerRadius(12)

          // Payment Method Header
          HStack {
            Text("请选择支付方式")
              .font(.system(size: 14))
              .foregroundColor(Color(hex: "0x666666"))
            Spacer()
          }
          .padding(.horizontal, 4)

          // WeChat Pay Option
          Button {
            isWeChatSelected = true
          } label: {
            HStack(spacing: 12) {
              Image("icon_wechat") // Ensure this icon exists or use system/placeholder
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(.green) // Fallback color if icon missing

              Text("微信支付")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "0x333333"))

              Spacer()

              Image(systemName: isWeChatSelected ? "checkmark.square.fill" : "square")
                .font(.system(size: 20))
                .foregroundColor(isWeChatSelected ? ThemeColor.brand500 : Color(hex: "0xCCCCCC"))
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
          }
        }
        .padding(16)
      }
      .background(Color(hex: "0xF8F8F8"))

      // Bottom Button
      VStack {
        Button {
          performPayment()
        } label: {
          Text("立即支付").FullBrandButton()
            .foregroundColor(.white)
            .contentShape(Rectangle())
        }
        .disabled(isProcessing)
      }
      .padding(16)
      .padding(.bottom, safeAreaBottom)
      .background(Color.white)
    }
    .ignoresSafeArea()
    .navigationBarHidden(true)
  }

  private func performPayment() {
    guard !isProcessing else { return }
    isProcessing = true

    Task {
      // 1. Get User Mobile
      guard let mobile = SelfStore.shared.mobile else {
        await MainActor.run {
          ToastCenter.shared.show("用户信息缺失，请重新登录")
          isProcessing = false
        }
        return
      }

      // 2. Create Order
      let appId = AppConst.wechatAppId
      if appId.isEmpty {
        await MainActor.run {
          ToastCenter.shared.show("微信AppID未配置")
          isProcessing = false
        }
        return
      }

      let payload = OrderCreatePayload(
        mobile: mobile,
        packageId: package.id,
        appid: appId,
        imei: imei
      )

      // Note: create API returns WechatPayParamsData? directly
      let result = await OrderAPI.shared.create(payload: payload)

      await MainActor.run {
        isProcessing = false
        if let params = result {
          // DONE-AI: 使用后端返回参数，避免防御性默认值
          let appId = params.appId.trimmingCharacters(in: .whitespacesAndNewlines)
          let partnerId = params.partnerId.trimmingCharacters(in: .whitespacesAndNewlines)
          let prepayId = params.prepayId.trimmingCharacters(in: .whitespacesAndNewlines)
          let nonceStr = params.nonceStr.trimmingCharacters(in: .whitespacesAndNewlines)
          let packageValue = params.package.trimmingCharacters(in: .whitespacesAndNewlines)
          let signType = params.signType.trimmingCharacters(in: .whitespacesAndNewlines)
          let timeStampText = String(params.timeStamp)
          print(
            "WeChatPay order_create success orderId=\(params.orderId) appId=\(appId) partnerId=\(partnerId) prepayId=\(prepayId) nonceLen=\(nonceStr.count) package=\(packageValue) signType=\(signType) timeStamp=\(timeStampText)"
          )
          // 3. Call WeChat SDK
          invokeWeChatPay(params: params)
        } else {
          print("WeChatPay order_create failed")
          ToastCenter.shared.showDetail("创建订单失败，请检查网络或订单参数")
        }
      }
    }
  }

  private func invokeWeChatPay(params: WechatPayParamsData) {
    // 微信SDK状态检查
    let installed = WXApi.isWXAppInstalled()
    let apiVersion = WXApi.getVersion()

    print("WeChatPay check: installed=\(installed), version=\(apiVersion)")

    if !installed {
      print("WeChatPay wx_installed=false")
      ToastCenter.shared.showDetail("未安装微信，无法发起支付")
      return
    }

    let appId = params.appId
    let universalLink = AppConst.wechatUniversalLink.trimmingCharacters(in: .whitespacesAndNewlines)

    print("WeChatPay invoke: appId=\(appId), universalLink=\(universalLink)")

    WXApi.registerApp(appId, universalLink: universalLink)

    let req = PayReq()
    req.partnerId = params.partnerId
    req.prepayId = params.prepayId
    req.nonceStr = params.nonceStr
    req.timeStamp = params.timeStamp
    req.package = params.package
    req.sign = params.sign

    WXApi.send(req)
  }
}
