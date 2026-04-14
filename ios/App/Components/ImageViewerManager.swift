import ImageViewer
import Photos
import UIKit

// 有一些其他功能，我屏蔽了。包括：
// See All 和 Delete

@MainActor
final class ImageViewerManager {
  static let shared = ImageViewerManager()

  private var presentedGallery: GalleryViewController?
  private var orientationToken: UUID?

  private init() {}

  func show(url: URL) {
    let itemsDataSource = SingleImageGalleryDataSource(imageURL: url)
    present(itemsDataSource: itemsDataSource)
  }

  // DONE-AI: 已抽出公共展示逻辑，避免重复代码
  func show(image: UIImage) {
    let itemsDataSource = SingleLocalImageGalleryDataSource(image: image)
    present(itemsDataSource: itemsDataSource)
  }

  func show(localPhotoAssets: [PHAsset], startIndex: Int) {
    guard !localPhotoAssets.isEmpty else { return }
    let itemsDataSource = LocalAssetGalleryDataSource(assets: localPhotoAssets)
    present(itemsDataSource: itemsDataSource, startIndex: startIndex)
  }

  private func present(itemsDataSource: GalleryItemsDataSource, startIndex: Int = 0) {
    if let presentedGallery {
      if presentedGallery.presentingViewController != nil {
        return
      }
      cleanupAfterDismiss()
    }

    guard let presenter = Self.topMostViewController() else { return }

    let itemCount = max(itemsDataSource.itemCount(), 1)
    let safeStartIndex = min(max(startIndex, 0), itemCount - 1)
    let gallery = GalleryViewController(startIndex: safeStartIndex, itemsDataSource: itemsDataSource, configuration: [
      GalleryConfigurationItem.deleteButtonMode(.none),
      GalleryConfigurationItem.seeAllCloseButtonMode(.none),
      GalleryConfigurationItem.thumbnailsButtonMode(.none),
    ])

    let clearState: () -> Void = { [weak self] in
      Task { @MainActor in
        self?.cleanupAfterDismiss()
      }
    }

    gallery.closedCompletion = clearState
    gallery.programmaticallyClosedCompletion = clearState
    gallery.swipedToDismissCompletion = clearState

    orientationToken = OrientationManager.shared.push(.allButUpsideDown)
    presentedGallery = gallery
    presenter.presentImageGallery(gallery)
  }

  func hide(animated: Bool = false) {
    guard let gallery = presentedGallery else { return }
    guard let presenting = gallery.presentingViewController else {
      cleanupAfterDismiss()
      return
    }
    presenting.dismiss(animated: animated) { [weak self] in
      self?.cleanupAfterDismiss()
    }
  }

  private func cleanupAfterDismiss() {
    presentedGallery = nil
    if let token = orientationToken {
      orientationToken = nil
      OrientationManager.shared.pop(token)
    }
  }

  private static func topMostViewController() -> UIViewController? {
    let windows = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }

    let keyWindow = windows.first(where: { $0.isKeyWindow }) ?? windows.first
    guard let root = keyWindow?.rootViewController else { return nil }
    return topMostViewController(from: root)
  }

  private static func topMostViewController(from root: UIViewController) -> UIViewController {
    if let presented = root.presentedViewController {
      return topMostViewController(from: presented)
    }
    if let nav = root as? UINavigationController, let visible = nav.visibleViewController {
      return topMostViewController(from: visible)
    }
    if let tab = root as? UITabBarController, let selected = tab.selectedViewController {
      return topMostViewController(from: selected)
    }
    return root
  }
}

private final class SingleImageGalleryDataSource: GalleryItemsDataSource {
  private let imageURL: URL

  init(imageURL: URL) {
    self.imageURL = imageURL
  }

  func itemCount() -> Int {
    1
  }

  func provideGalleryItem(_: Int) -> GalleryItem {
    .image(fetchImageBlock: { completion in
      let task = URLSession.shared.dataTask(with: self.imageURL) { data, _, _ in
        let image: UIImage? = data.flatMap(UIImage.init(data:))
        DispatchQueue.main.async {
          completion(image)
        }
      }
      task.resume()
    })
  }
}

private final class SingleLocalImageGalleryDataSource: GalleryItemsDataSource {
  private let image: UIImage

  init(image: UIImage) {
    self.image = image
  }

  func itemCount() -> Int {
    1
  }

  func provideGalleryItem(_: Int) -> GalleryItem {
    .image(fetchImageBlock: { completion in
      DispatchQueue.main.async {
        completion(self.image)
      }
    })
  }
}

private final class LocalAssetGalleryDataSource: GalleryItemsDataSource {
  private let assets: [PHAsset]

  init(assets: [PHAsset]) {
    self.assets = assets
  }

  func itemCount() -> Int {
    assets.count
  }

  func provideGalleryItem(_ index: Int) -> GalleryItem {
    .image(fetchImageBlock: { completion in
      guard self.assets.indices.contains(index) else {
        DispatchQueue.main.async {
          completion(nil)
        }
        return
      }

      let options = PHImageRequestOptions()
      options.isNetworkAccessAllowed = true
      options.deliveryMode = .highQualityFormat
      options.resizeMode = .none

      PHImageManager.default().requestImage(
        for: self.assets[index],
        targetSize: PHImageManagerMaximumSize,
        contentMode: .aspectFit,
        options: options
      ) { image, _ in
        DispatchQueue.main.async {
          completion(image)
        }
      }
    })
  }
}
