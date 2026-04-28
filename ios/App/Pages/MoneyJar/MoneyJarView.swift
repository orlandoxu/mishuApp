import SwiftUI

struct MoneyJarView: View {
  @State private var budgetMode = "expense"
  @State private var showSettings = false

  private let transactions = [
    MoneyTransaction(id: "1", type: "expense", amount: 35, category: "餐饮", date: "2024-04-24", note: "午餐"),
    MoneyTransaction(id: "2", type: "expense", amount: 15, category: "交通", date: "2024-04-24", note: "公交"),
    MoneyTransaction(id: "3", type: "expense", amount: 88, category: "其他", date: "2024-04-23", note: "超市购物"),
    MoneyTransaction(id: "4", type: "income", amount: 300, category: "兼职", date: "2024-04-23", note: "设计稿酬")
  ]

  private var totalIncome: Int { transactions.filter { $0.type == "income" }.map(\.amount).reduce(0, +) }
  private var totalExpense: Int { transactions.filter { $0.type == "expense" }.map(\.amount).reduce(0, +) }
  private var limit: Int { budgetMode == "expense" ? 500 : 1000 }
  private var progress: Double { Double(budgetMode == "expense" ? totalExpense : totalIncome) / Double(limit) }

  var body: some View {
    ZStack(alignment: .bottom) {
      Color(hex: "#F8F9FB").ignoresSafeArea()

      VStack(spacing: 0) {
        NavHeader(title: "小钱罐") {
          Button {
            showSettings = true
          } label: {
            Image(systemName: "gearshape.fill")
              .foregroundColor(.black.opacity(0.58))
              .frame(width: 44, height: 44)
          }
        }

        ScrollView(showsIndicators: false) {
          VStack(spacing: 20) {
            Text("本周")
              .font(.system(size: 15, weight: .black))
              .foregroundColor(.black.opacity(0.58))
              .frame(maxWidth: .infinity)
              .padding(.vertical, 12)
              .background(Color.white)
              .clipShape(Capsule())

            MoneyBudgetCard(mode: budgetMode, progress: progress, limit: limit) {
              budgetMode = budgetMode == "expense" ? "income" : "expense"
            }
            MoneyStatCards(expense: totalExpense, income: totalIncome)
            MoneyTransactionList(transactions: transactions)
          }
          .padding(.horizontal, 20)
          .padding(.top, 16)
          .padding(.bottom, 38)
        }
      }

      if showSettings {
        VStack(spacing: 14) {
          Capsule().fill(Color.black.opacity(0.16)).frame(width: 42, height: 5)
          Text("预算设置").font(.system(size: 20, weight: .black))
          Text("当前\(budgetMode == "expense" ? "支出预算" : "收入目标")：¥\(limit)")
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.black.opacity(0.55))
          Button("完成") { showSettings = false }
            .font(.system(size: 16, weight: .black))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Color.black)
            .clipShape(Capsule())
        }
        .padding(22)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(20)
        .shadow(color: .black.opacity(0.15), radius: 28, x: 0, y: 12)
      }
    }
  }
}
