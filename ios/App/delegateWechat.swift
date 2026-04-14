import Foundation

enum WeChatPayCallbackHandler {
  static func handleIncomingURL(_ url: URL, source: String) {
    let path = url.path
    print("[WeChatPay][\(source)] path=\(path)")

    if path.contains("/pay") {
      handlePayReturnURL(url, source: source)
    }
  }

  static func handleUserActivity(_ userActivity: NSUserActivity, source: String) {
    if let url = userActivity.webpageURL {
      handleIncomingURL(url, source: source)
    }
  }

  static func handlePayReturnURL(_ url: URL, source: String) {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
    let items = components.queryItems ?? []
    let retValue = items.first(where: { $0.name == "ret" })?.value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let retMsg = items.first(where: { $0.name == "retmsg" })?.value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

    Task { @MainActor in
      applyPayResult(retValue: retValue, retMsg: retMsg, source: source)
    }
  }

  @MainActor
  static func applyPayResult(retValue: String, retMsg: String, source _: String) {
    switch retValue {
    case "0":
      ToastCenter.shared.show("支付成功")
    case "-2":
      ToastCenter.shared.show("已取消支付")
    default:
      ToastCenter.shared.show(retMsg.isEmpty ? "支付失败" : retMsg)
    }
  }
}
