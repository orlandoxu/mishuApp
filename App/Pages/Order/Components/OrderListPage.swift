import SwiftUI

struct OrderListPage: View {
  let orders: [OrderModel]

  var body: some View {
    if orders.isEmpty {
      VStack {
        Spacer()
        Text("暂无订单")
          .foregroundColor(Color(hex: "0x999999"))
          .font(.system(size: 14))
        Spacer()
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    } else {
      ScrollView {
        LazyVStack(spacing: 12) {
          ForEach(orders) { order in
            OrderCardView(order: order)
          }
        }
        .padding(.vertical, 40)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
  }
}
