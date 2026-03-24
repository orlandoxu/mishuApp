import Foundation

// DONE-AI: 项目不使用 Combine，保留空壳避免旧引用导致编译失败
final class CancellableBag {
  static let shared = CancellableBag()

  private init() {}

  func clear() {}
}
