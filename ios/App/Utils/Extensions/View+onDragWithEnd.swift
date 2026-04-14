import Foundation
import SwiftUI
import UniformTypeIdentifiers

/**
 * 该插件是为了解决两个问题：
 * 问题一：swiftUI中，onDrag没有拖拽结束事件
 * 该方法，是利用NSItemProvider的deinit方法，来触发拖拽结束事件
 * 因为NSItemProvider在拖拽结束时，会自动调用deinit方法
 * 问题二：onDrag会触发两次（结束时候会再触发一次）
 * 很尴尬的是，官方文档，以及google都没有查询到相关的资料
 * 所以不确定是不是所有ios都会开始和结束都触发一次。还是说是一个bug
 * 所以该方法中，使用了一种方法，来解决触发两次的问题
 *
 * 如果确认所有手机中，onDrag都会在开始和结束时候触发一次，那就更简单了
 */

// 修复NSItemProvider在拖拽结束时不会触发的问题
class NSFixItemProvider: NSItemProvider {
  var didEnd: (() -> Void)?

  deinit {
    didEnd?()  // << here !!
  }
}

/// 封装的拖拽插件，提供拖拽结束检测功能
/// 解决SwiftUI原生onDrag没有拖拽结束事件的问题
extension View {
  /**
   * 带有拖拽结束检测的拖拽修饰器
   * - Parameters:
   *   - id: 拖拽项的唯一标识符
   *   - data: 拖拽数据或提供拖拽数据的闭包
   *   - onDragStart: 拖拽开始时的回调
   *   - onDragEnd: 拖拽结束时的回调
   * - Returns: 添加了拖拽功能的视图
   */
  func onDragWithEnd<T: NSItemProviderWriting>(
    id: String,
    data: @escaping () -> T,
    onDragStart: @escaping () -> Void = {},
    onDragEnd: @escaping () -> Void
  ) -> some View {
    self.onDrag {
      // 检查是否在激活的拖拽中
      if DragManager.shared.isIdActive(id) {
        // print("拖拽仍在进行中，忽略重复的onDrag调用: \(id)")
        return NSItemProvider()
      }

      // 执行拖拽开始回调
      // print("创建拖拽: \(id)")

      // 注册拖拽
      DragManager.shared.registerDrag(
        id: id,
        onStart: onDragStart,
        onEnd: onDragEnd
      )

      // 获取数据
      let dataValue = data()

      // 创建带有结束回调的Provider
      let provider = NSFixItemProvider(object: dataValue)
      provider.didEnd = {
        // 通知管理器拖拽结束
        DragManager.shared.notifyDragEnd(id: id)
      }

      return provider
    }
  }

  // 便利方法 - 直接接受数据而非闭包
  func onDragWithEnd<T: NSItemProviderWriting>(
    id: String,
    data: T,
    onDragStart: @escaping () -> Void = {},
    onDragEnd: @escaping () -> Void
  ) -> some View {
    self.onDragWithEnd(
      id: id,
      data: { data },
      onDragStart: onDragStart,
      onDragEnd: onDragEnd
    )
  }
}

/// 拖拽管理器 - 确保拖拽事件的全局状态管理
class DragManager {
  static let shared = DragManager()

  private var activeDrags: [String: DragState] = [:]
  private let lock = NSLock()

  private init() {}

  /// 检查指定ID的拖拽是否处于激活状态
  func isIdActive(_ id: String) -> Bool {
    lock.lock()
    defer { lock.unlock() }
    return activeDrags[id] != nil
  }

  /// 注册一个新的拖拽
  func registerDrag(
    id: String,
    onStart: @escaping () -> Void,
    onEnd: @escaping () -> Void
  ) {
    lock.lock()
    defer { lock.unlock() }

    // 如果已存在，先清理掉旧的
    if let existingDrag = activeDrags[id] {
      print("警告：ID为\(id)的拖拽已存在，将被替换")
      existingDrag.cancel()
    }

    // 创建新的拖拽状态
    let dragState = DragState(onEnd: onEnd)
    activeDrags[id] = dragState

    // 执行开始回调（解锁后执行，避免死锁）
    DispatchQueue.main.async {
      onStart()
    }
  }

  /// 通知拖拽结束
  func notifyDragEnd(id: String) {
    lock.lock()

    guard let dragState = activeDrags[id], !dragState.isCompleted else {
      lock.unlock()
      print("拖拽ID \(id) 不存在或已完成")
      return
    }

    // 标记为已完成
    dragState.isCompleted = true

    // 移除拖拽状态
    activeDrags.removeValue(forKey: id)
    lock.unlock()

    // 在主线程执行结束回调
    print("结束拖拽: \(id)")
    DispatchQueue.main.async {
      dragState.onEnd()
    }

    // 延迟清理，确保不会过早接受下一个相同ID的拖拽
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
      guard let self = self else { return }
      self.lock.lock()
      defer { self.lock.unlock() }

      // 双重检查防止竞态条件
      if self.activeDrags[id]?.isCompleted == true {
        self.activeDrags.removeValue(forKey: id)
      }
    }
  }

  /// 取消所有活跃的拖拽
  func cancelAllDrags() {
    lock.lock()
    let currentDrags = activeDrags
    activeDrags.removeAll()
    lock.unlock()

    // 在主线程上调用所有取消
    DispatchQueue.main.async {
      for (id, dragState) in currentDrags {
        print("取消拖拽: \(id)")
        dragState.cancel()
      }
    }
  }
}

/// 拖拽状态
private class DragState {
  let onEnd: () -> Void
  var isCompleted = false

  init(onEnd: @escaping () -> Void) {
    self.onEnd = onEnd
  }

  func cancel() {
    if !isCompleted {
      isCompleted = true
    }
  }
}
