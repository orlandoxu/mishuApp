import Foundation

// DONE-AI: 已移除意图/编号规则路由，仅保留通用文本拼接工具。

/// 路由流程公用的文本工具。
enum TextTools {
  /// 将原始输入与补充输入合并为单条上下文文本。
  static func mergeText(originInput: String, supplementInput: String) -> String {
    let origin = originInput.trimmingCharacters(in: .whitespacesAndNewlines)
    let supplement = supplementInput.trimmingCharacters(in: .whitespacesAndNewlines)
    if origin.isEmpty { return supplement }
    if supplement.isEmpty { return origin }
    return "\(origin)；补充说明：\(supplement)"
  }
}

/// 兼容历史调用点，后续可在统一迁移后删除。
enum TextClean {
  static func joinAsk(originInput: String, supplementInput: String) -> String {
    TextTools.mergeText(originInput: originInput, supplementInput: supplementInput)
  }
}
