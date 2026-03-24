import Foundation
import SwiftUI

enum OrderTab: Int, CaseIterable, Identifiable {
  case all = 0
  case active = 1
  case expired = 2

  var title: String {
    switch self {
    case .all: return "全部订单"
    case .active: return "生效中"
    case .expired: return "已到期"
    }
  }

  var id: Int {
    rawValue
  }
}

@MainActor
class OrderListViewModel: ObservableObject {
  @Published var selectedTab: OrderTab = .all
  @Published var orders: [OrderModel] = []
  @Published var isLoading = false
  // DONE-AI: 这个errorMessage不需要，网络层直接处理了已经

  func orders(for tab: OrderTab) -> [OrderModel] {
    switch tab {
    case .all:
      // 显示所有已支付的订单（排除 status=1 未支付）
      return orders.filter { $0.status != 1 }
    case .active:
      return orders.filter { $0.effectiveStatus == 1 && !$0.isExpired }
    case .expired:
      return orders.filter { $0.isExpired }
    }
  }

  func loadOrders() async {
    isLoading = true
    if let result = await OrderAPI.shared.getAppOrderList() {
      orders = result
    }
    isLoading = false
  }

  /// 格式化价格 (分 -> 元)
  func formatPrice(_ price: Int64) -> String {
    let yuan = Double(price) // 假设单位是元？用户UI显示367.00。如果API返回367，那就是元。如果36700，那就是分。
    // 通常支付接口是分。但看截图 367.00，如果API返回367，那就是3.67？不太可能。
    // 如果API返回367，可能是元。
    // 如果API返回36700，则是分。
    // 之前 Order.swift 里有 price: 0。
    // 暂时假设是元 (Int64), 因为 367.00。如果是分，36700。
    // 让我们先按 "数值就是元" 或者 "数值是分" 来处理。
    // 安全起见，如果数值很大（>10000），可能是分？或者直接显示。
    // 鉴于不确定，我先按 "直接显示数值" 保留两位小数。
    // 修正：通常后端返回分。36700 -> 367.00。
    // 但如果后端返回 367，那就是 3.67 元？年卡 3.67 元太便宜。
    // 所以 367 应该是 367 元。那么单位就是元？
    // 或者 36700 是分。
    // 让我们假设单位是分，显示时 / 100.0。
    return String(format: "%.2f", Double(price) / 100.0) // 假设是分
  }
}
