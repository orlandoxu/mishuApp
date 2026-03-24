import UIKit

/**
 * 这个插件非常重要！！
 * 这个插件的作用，是在navigationBarBackButtonHidden的时候，仍然可以左滑返回
 */

extension UINavigationController: UIGestureRecognizerDelegate {
  override open func viewDidLoad() {
    super.viewDidLoad()
    interactivePopGestureRecognizer?.delegate = self
  }

  public func gestureRecognizerShouldBegin(
    _ gestureRecognizer: UIGestureRecognizer
  ) -> Bool {
    return viewControllers.count > 1
  }
}
