import Foundation

// DONE-AI: 多轮会话状态由 actor 管理，避免并发读写冲突。

/// 多轮路由流程中的待处理状态。
enum PendingState: Equatable {
  case waitAsk(originInput: String, question: String)
  case waitAdd(baseText: String)
  case waitPick(candidates: [MemoryRecord], editText: String)
  case waitEdit(target: MemoryRecord)
}

/// 按用户隔离的内存会话状态存储，带过期时间控制。
actor SessionStore {
  static let shared = SessionStore()

  /// 会话条目：保存状态本体与最近更新时间。
  private struct SessionItem {
    let state: PendingState
    let updatedAt: Date
  }

  private var entries: [String: SessionItem] = [:]
  private let ttlSec: TimeInterval = 10 * 60

  /// 写入某个用户的待处理状态。
  func set(_ state: PendingState, for userId: String) {
    entries[userId] = SessionItem(state: state, updatedAt: Date())
  }

  /// 读取某个用户的待处理状态；不存在或过期时返回 nil。
  func get(for userId: String) -> PendingState? {
    guard let entry = entries[userId] else { return nil }
    if Date().timeIntervalSince(entry.updatedAt) > ttlSec {
      entries[userId] = nil
      return nil
    }
    return entry.state
  }

  /// 清除某个用户的待处理状态。
  func clear(for userId: String) {
    entries[userId] = nil
  }
}
