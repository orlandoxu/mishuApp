import WechatOpenSDK

enum WeChatPayCallbackHandler {
  static func handleIncomingURL(_ url: URL, source: String) {
    let scheme = url.scheme ?? ""
    let host = url.host ?? ""
    let path = url.path
    let query = sanitizeQuery(from: url)
    print("[WeChatPay][\(source)] url scheme=\(scheme) host=\(host) path=\(path) query=\(query)")

    if path.contains("/pay") {
      handlePayReturnURL(url, source: source)
    }
  }

  static func handleUserActivity(_ userActivity: NSUserActivity, source: String) {
    let activityType = userActivity.activityType
    let webpageURL = userActivity.webpageURL
    print("[WeChatPay][\(source)] userActivity type=\(activityType) webpageURL=\(String(describing: webpageURL))")

    if let url = webpageURL {
      handleIncomingURL(url, source: source)
    }
  }

  static func handlePayReturnURL(_ url: URL, source: String) {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
      print("[WeChatPay][\(source)] URLComponents failed")
      return
    }

    let items = components.queryItems ?? []
    let retValue = items.first(where: { $0.name == "ret" })?.value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let retMsg = items.first(where: { $0.name == "retmsg" })?.value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    print("[WeChatPay][\(source)] pay_return ret=\(retValue) retmsg=\(retMsg)")

    Task { @MainActor in
      applyPayResult(retValue: retValue, retMsg: retMsg, source: source)
    }
  }

  @MainActor
  static func applyPayResult(retValue: String, retMsg: String, source: String) {
    let nav = AppNavigationModel.shared
    let top = nav.last()
    print("[WeChatPay][\(source)] applyPayResult ret=\(retValue) top=\(String(describing: top))")

    switch retValue {
    case "0":
      if top == .paymentSuccess {
        print("[WeChatPay][\(source)] skip navigation (already on paymentSuccess)")
        return
      }
      nav.push(.paymentSuccess)
    case "-2":
      ToastCenter.shared.show("已取消支付")
    default:
      let message = retMsg.isEmpty ? "支付失败" : retMsg
      ToastCenter.shared.show(message)
    }
  }

  private static func sanitizeQuery(from url: URL) -> String {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return "" }
    let items = components.queryItems ?? []
    if items.isEmpty { return "" }
    return items.map { item in
      let key = item.name
      let value = (item.value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      if key.lowercased().contains("token") || key.lowercased().contains("auth") {
        return "\(key)=<masked>"
      }
      if value.count > 120 {
        let prefix = value.prefix(16)
        let suffix = value.suffix(8)
        return "\(key)=\(prefix)...\(suffix)"
      }
      return "\(key)=\(value)"
    }.joined(separator: "&")
  }
}

final class WeChatOpenSDKDelegate: NSObject, WXApiDelegate {
  func onReq(_: BaseReq) {}

  func onResp(_ resp: BaseResp) {
    guard let payResp = resp as? PayResp else { return }

    Task { @MainActor in
      let errCode = payResp.errCode
      let errStr = payResp.errStr.trimmingCharacters(in: .whitespacesAndNewlines)

      switch errCode {
      case 0:
        WeChatPayCallbackHandler.applyPayResult(retValue: "0", retMsg: "", source: "WXApiDelegate.onResp")
      case -2:
        WeChatPayCallbackHandler.applyPayResult(retValue: "-2", retMsg: "", source: "WXApiDelegate.onResp")
      default:
        WeChatPayCallbackHandler.applyPayResult(retValue: String(errCode), retMsg: errStr, source: "WXApiDelegate.onResp")
      }
    }
  }
}
