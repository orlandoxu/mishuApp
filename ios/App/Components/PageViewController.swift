import SwiftUI
import UIKit

struct PageViewController: UIViewControllerRepresentable {
  let pages: [UIViewController]
  @Binding var currentPage: Int
  var isUserInteractionEnabled: Bool = false

  func makeUIViewController(context: Context) -> UIPageViewController {
    let pageViewController = UIPageViewController(
      transitionStyle: .scroll,
      navigationOrientation: .horizontal,
      options: [:]
    )
    pageViewController.dataSource = isUserInteractionEnabled ? context.coordinator : nil
    pageViewController.delegate = context.coordinator

    markControllerIndexes()
    if let initialIndex = safeTargetIndex(currentPage) {
      context.coordinator.currentPageIndex = initialIndex
      pageViewController.setViewControllers(
        [pages[initialIndex]],
        direction: .forward,
        animated: false
      )
    }

    applyInteractionSetting(to: pageViewController)
    return pageViewController
  }

  func updateUIViewController(_ pageViewController: UIPageViewController, context: Context) {
    markControllerIndexes()

    guard let targetIndex = safeTargetIndex(currentPage) else {
      applyInteractionSetting(to: pageViewController)
      return
    }

    let displayedController = pageViewController.viewControllers?.first
    let currentIndex = displayedController
      .flatMap { index(of: $0, fallback: context.coordinator.currentPageIndex) }
      ?? context.coordinator.currentPageIndex
      ?? targetIndex

    let direction: UIPageViewController.NavigationDirection = targetIndex >= currentIndex
      ? .forward
      : .reverse

    pageViewController.setViewControllers(
      [pages[targetIndex]],
      direction: direction,
      animated: targetIndex != currentIndex
    )
    context.coordinator.currentPageIndex = targetIndex

    applyInteractionSetting(to: pageViewController)
  }

  private func safeTargetIndex(_ index: Int) -> Int? {
    guard pages.isEmpty == false else { return nil }
    if pages.indices.contains(index) {
      return index
    }
    return min(max(index, 0), pages.count - 1)
  }

  private func markControllerIndexes() {
    for (index, page) in pages.enumerated() {
      page.view.tag = index
    }
  }

  private func index(of controller: UIViewController, fallback: Int?) -> Int? {
    if let index = pages.firstIndex(of: controller) {
      return index
    }
    let taggedIndex = controller.view.tag
    if pages.indices.contains(taggedIndex) {
      return taggedIndex
    }
    return fallback
  }

  private func applyInteractionSetting(to pageViewController: UIPageViewController) {
    for view in pageViewController.view.subviews {
      guard let scrollView = view as? UIScrollView else { continue }
      scrollView.isScrollEnabled = isUserInteractionEnabled
      // 仅禁止左右滑动，保留子视图点击事件（按钮等）
      scrollView.isUserInteractionEnabled = true
      scrollView.panGestureRecognizer.isEnabled = isUserInteractionEnabled
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    var parent: PageViewController
    var currentPageIndex: Int?

    init(_ parent: PageViewController) {
      self.parent = parent
    }

    func pageViewController(
      _ pageViewController: UIPageViewController,
      viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
      guard let index = parent.index(of: viewController, fallback: currentPageIndex), index > 0 else {
        return nil
      }
      return parent.pages[index - 1]
    }

    func pageViewController(
      _ pageViewController: UIPageViewController,
      viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
      guard let index = parent.index(of: viewController, fallback: currentPageIndex),
            index < parent.pages.count - 1 else {
        return nil
      }
      return parent.pages[index + 1]
    }

    func pageViewController(
      _ pageViewController: UIPageViewController,
      didFinishAnimating finished: Bool,
      previousViewControllers: [UIViewController],
      transitionCompleted completed: Bool
    ) {
      if completed,
         let currentVC = pageViewController.viewControllers?.first,
         let index = parent.index(of: currentVC, fallback: currentPageIndex)
      {
        currentPageIndex = index
        parent.currentPage = index
      }
    }
  }
}
