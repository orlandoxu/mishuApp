import Foundation

// DONE-AI: 路由初筛使用 embedding 相似度，不使用关键词规则。
// DONE-AI: 已将本文件注释统一为中文，便于团队维护。

/// 内存中的意图向量索引，用于路由动作的 embedding 初筛。
actor IntentEmbedIndex {
  static let shared = IntentEmbedIndex()

  private var actionVectors: [RouteAction: [Double]] = [:]
  private var isBooted = false

  /// 基于余弦相似度，从动作中心向量中选出 TopK 候选动作。
  func pickActions(
    text: String,
    runtime: RouteRuntime,
    topK: Int
  ) async -> [RouteAction] {
    // 空输入优先走安全动作，避免误判。
    guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      return [.clarify, .chat]
    }

    await bootIfNeed(runtime: runtime)

    guard let queryVector = await runtime.embedText(text), !actionVectors.isEmpty else {
      return [.store, .retrieve, .amend, .clarify, .chat]
    }

    let scored = actionVectors.compactMap { action, center -> (RouteAction, Double)? in
      guard center.count == queryVector.count else { return nil }
      return (action, cosine(queryVector, center))
    }
    .sorted { $0.1 > $1.1 }

    let k = max(2, min(topK, scored.count))
    let top = Array(scored.prefix(k)).map(\.0)
    if top.isEmpty {
      return [.store, .retrieve, .amend, .clarify, .chat]
    }

    if top.contains(.clarify) {
      return top
    }
    return top + [.clarify]
  }

  /// 按需初始化动作中心向量，样本来自运行时提供的种子短句。
  private func bootIfNeed(runtime: RouteRuntime) async {
    guard !isBooted else { return }

    let seedTexts = await runtime.seedTexts()
    var centroids: [RouteAction: [Double]] = [:]

    for (action, phrases) in seedTexts {
      let rows = await embedRows(phrases, runtime: runtime)
      if let center = averageVector(rows) {
        centroids[action] = center
      }
    }

    if !centroids.isEmpty {
      actionVectors = centroids
      isBooted = true
    }
  }

  /// 将一组样本短句转成向量列表。
  private func embedRows(_ phrases: [String], runtime: RouteRuntime) async -> [[Double]] {
    var rows: [[Double]] = []
    for phrase in phrases {
      if let embedding = await runtime.embedText(phrase) {
        rows.append(embedding)
      }
    }
    return rows
  }

  /// 计算多个向量的均值中心。
  private func averageVector(_ rows: [[Double]]) -> [Double]? {
    guard let first = rows.first else { return nil }
    var sum = Array(repeating: 0.0, count: first.count)

    for vector in rows where vector.count == first.count {
      for index in vector.indices {
        sum[index] += vector[index]
      }
    }

    let divisor = Double(rows.count)
    guard divisor > 0 else { return nil }
    return sum.map { $0 / divisor }
  }

  /// 计算两个向量的余弦相似度。
  private func cosine(_ lhs: [Double], _ rhs: [Double]) -> Double {
    guard lhs.count == rhs.count, !lhs.isEmpty else { return -1 }

    var dot = 0.0
    var lhsNorm = 0.0
    var rhsNorm = 0.0

    for index in lhs.indices {
      let lv = lhs[index]
      let rv = rhs[index]
      dot += lv * rv
      lhsNorm += lv * lv
      rhsNorm += rv * rv
    }

    let denom = sqrt(lhsNorm) * sqrt(rhsNorm)
    if denom == 0 { return -1 }
    return dot / denom
  }
}
