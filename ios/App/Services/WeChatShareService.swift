import Foundation
import UIKit

#if canImport(WechatOpenSDK)
  import WechatOpenSDK
#endif

enum WeChatShareScene {
  case session
  case timeline
}

struct WeChatShareCard {
  let title: String
  let description: String
  let webpageUrl: String
  let thumbImage: UIImage
}

enum WeChatShareResult {
  case sent
  case unavailable
  case failed
}

final class WeChatShareService: NSObject {
  static let shared = WeChatShareService()

  private override init() {
    super.init()
  }

  @discardableResult
  func register() -> Bool {
    #if canImport(WechatOpenSDK)
      guard !AppConst.wechatAppId.isEmpty, !AppConst.wechatUniversalLink.isEmpty else {
        return false
      }
      return WXApi.registerApp(AppConst.wechatAppId, universalLink: AppConst.wechatUniversalLink)
    #else
      return false
    #endif
  }

  var isWXAppInstalled: Bool {
    #if canImport(WechatOpenSDK)
      return WXApi.isWXAppInstalled()
    #else
      return false
    #endif
  }

  @MainActor
  func share(card: WeChatShareCard, scene: WeChatShareScene = .session) async -> WeChatShareResult {
    #if canImport(WechatOpenSDK)
      guard isWXAppInstalled else { return .unavailable }

      let webpageObject = WXWebpageObject()
      webpageObject.webpageUrl = card.webpageUrl

      let message = WXMediaMessage()
      message.title = card.title
      message.description = card.description
      message.mediaObject = webpageObject
      message.setThumbImage(Self.compressedThumbImage(card.thumbImage))

      let request = SendMessageToWXReq()
      request.bText = false
      request.message = message
      request.scene = Int32(scene == .session ? WXSceneSession.rawValue : WXSceneTimeline.rawValue)

      return await WXApi.send(request) ? .sent : .failed
    #else
      return .unavailable
    #endif
  }

  @MainActor
  func shareWithSystemSheet(text: String, urlString: String) {
    var items: [Any] = [text]
    if let url = URL(string: urlString) {
      items.append(url)
    } else {
      items.append(urlString)
    }

    let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
    guard let presenter = UIApplication.shared.activeTopViewController else { return }
    if let popover = controller.popoverPresentationController {
      popover.sourceView = presenter.view
      popover.sourceRect = CGRect(
        x: presenter.view.bounds.midX,
        y: presenter.view.bounds.midY,
        width: 1,
        height: 1
      )
      popover.permittedArrowDirections = []
    }
    presenter.present(controller, animated: true)
  }

  static func defaultThumbImage() -> UIImage {
    UIImage(named: "avatar_girl") ?? UIImage(named: "img_default_avatar") ?? UIImage()
  }

  static func thumbImage(from remoteURL: String?) async -> UIImage {
    let trimmed = (remoteURL ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    guard let url = URL(string: trimmed), !trimmed.isEmpty else {
      return defaultThumbImage()
    }

    do {
      let (data, response) = try await URLSession.shared.data(from: url)
      guard (response as? HTTPURLResponse)?.statusCode ?? 200 < 400,
            let image = UIImage(data: data)
      else {
        return defaultThumbImage()
      }
      return image
    } catch {
      return defaultThumbImage()
    }
  }

  private static func compressedThumbImage(_ image: UIImage) -> UIImage {
    var targetWidth: CGFloat = 120
    var candidate = squareImage(image, targetWidth: targetWidth)
    while let data = candidate.jpegData(compressionQuality: 0.72), data.count > 31 * 1024, targetWidth > 48 {
      targetWidth -= 12
      candidate = squareImage(image, targetWidth: targetWidth)
    }
    return candidate
  }

  private static func squareImage(_ image: UIImage, targetWidth: CGFloat) -> UIImage {
    let side = min(image.size.width, image.size.height)
    guard side > 0 else { return image }

    let cropRect = CGRect(
      x: (image.size.width - side) / 2,
      y: (image.size.height - side) / 2,
      width: side,
      height: side
    )

    guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
      return image.resize(targetWidth: targetWidth)
    }

    let cropped = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    return cropped.resize(targetWidth: targetWidth)
  }
}

#if canImport(WechatOpenSDK)
  extension WeChatShareService: WXApiDelegate {
    func onResp(_ resp: BaseResp) {
      let message: String
      switch resp.errCode {
      case 0:
        message = "分享成功"
      case -2:
        message = "已取消分享"
      default:
        let errorText = resp.errStr
        message = errorText.isEmpty ? "微信分享失败" : errorText
      }
      Task { @MainActor in
        ToastCenter.shared.show(message)
      }
    }
  }
#endif

private extension UIApplication {
  var activeTopViewController: UIViewController? {
    connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .first { $0.isKeyWindow }?
      .rootViewController?
      .topMostPresentedViewController
  }
}

private extension UIViewController {
  var topMostPresentedViewController: UIViewController {
    if let presentedViewController {
      return presentedViewController.topMostPresentedViewController
    }
    if let navigationController = self as? UINavigationController {
      return navigationController.visibleViewController?.topMostPresentedViewController ?? navigationController
    }
    if let tabBarController = self as? UITabBarController {
      return tabBarController.selectedViewController?.topMostPresentedViewController ?? tabBarController
    }
    return self
  }
}
