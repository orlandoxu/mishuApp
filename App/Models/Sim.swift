struct SimModel: Decodable {
  let iccId: String
  let thirdUrl: String
  let thirdUrlTitle: String
  let isXjCard: Bool
  let cardType: Int
  // 增加的
  let totalFlow: Int64
  let usedFlow: Int64
  let unusedFlow: Int64
  let flowSettleDay: String

  var totalFlowString: String {
    let gb = Double(max(0, totalFlow)) / (1024.0 * 1024.0 * 1024.0)
    if gb <= 0 {
      return "0GB"
    }
    if abs(gb.rounded() - gb) < 0.01 {
      return "\(Int(gb.rounded()))GB"
    }
    return String(format: "%.1f", gb).dropTailZero + "GB"
  }

  enum CodingKeys: String, CodingKey {
    case iccId
    case thirdUrl
    case thirdUrlTitle
    case isXjCard
    case cardType
    case totalFlow
    case usedFlow
    case unusedFlow
    case flowSettleDay
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    iccId = container.safeDecodeString(.iccId, "")
    thirdUrl = container.safeDecodeString(.thirdUrl, "")
    thirdUrlTitle = container.safeDecodeString(.thirdUrlTitle, "")
    isXjCard = container.safeDecodeBool(.isXjCard, false)
    cardType = container.safeDecodeInt(.cardType, 0)
    totalFlow = container.safeDecodeInt64(.totalFlow, 0)
    usedFlow = container.safeDecodeInt64(.usedFlow, 0)
    unusedFlow = container.safeDecodeInt64(.unusedFlow, 0)
    flowSettleDay = container.safeDecodeString(.flowSettleDay, "")
  }
}
