import UIKit

extension UIImage {
  /// 根据目标宽度缩放图片
  /// - Parameter targetWidth: 目标宽度
  /// - Returns: 缩放后的图片
  func resize(targetWidth: CGFloat) -> UIImage {
    // 如果原图宽度小于目标宽度，直接返回原图
    if self.size.width <= targetWidth {
      return self
    }

    // 计算缩放比例
    let scale = targetWidth / self.size.width
    let targetHeight = self.size.height * scale
    let targetSize = CGSize(width: targetWidth, height: targetHeight)

    // 创建绘制上下文
    UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
    defer { UIGraphicsEndImageContext() }

    // 绘制缩放后的图片
    self.draw(in: CGRect(origin: .zero, size: targetSize))

    // 获取结果图片
    guard let resizedImage = UIGraphicsGetImageFromCurrentImageContext() else {
      return self
    }

    return resizedImage
  }
}
