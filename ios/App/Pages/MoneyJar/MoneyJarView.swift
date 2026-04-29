import SwiftUI

struct MoneyJarView: View {
  @State private var budgetMode = "expense"
  @State private var showSettings = false
  @State private var selectedDate = Date.mishuMoneyJarSeed
  @State private var showWeekPicker = false
  @State private var budgetLimit = 500
  @State private var incomeGoal = 1000

  private let transactions = [
    MoneyTransaction(id: "1", type: "expense", amount: 35, category: "餐饮", date: "2024-04-24", note: "午餐"),
    MoneyTransaction(id: "2", type: "expense", amount: 15, category: "交通", date: "2024-04-24", note: "公交"),
    MoneyTransaction(id: "3", type: "expense", amount: 88, category: "其他", date: "2024-04-23", note: "超市购物"),
    MoneyTransaction(id: "4", type: "income", amount: 300, category: "兼职", date: "2024-04-23", note: "设计稿酬"),
  ]

  private var totalIncome: Int {
    transactions.filter { $0.type == "income" }.map(\.amount).reduce(0, +)
  }

  private var totalExpense: Int {
    transactions.filter { $0.type == "expense" }.map(\.amount).reduce(0, +)
  }

  private var limit: Int {
    budgetMode == "expense" ? budgetLimit : incomeGoal
  }

  private var progress: Double {
    Double(budgetMode == "expense" ? totalExpense : totalIncome) / Double(limit)
  }

  private var currentWeekTitle: String {
    selectedDate.moneyJarWeekTitle
  }

  var body: some View {
    ZStack(alignment: .bottom) {
      Color(hex: "#F8F9FB").ignoresSafeArea()

      VStack(spacing: 0) {
        NavHeader(title: "小钱罐", topPadding: 0, bottomPadding: 12) {
          Button {
            showMoneySettings()
          } label: {
            Image(systemName: "gearshape.fill")
              .font(.system(size: 24, weight: .semibold))
              .foregroundColor(Color.black.opacity(0.58))
              .frame(width: 44, height: 44)
          }
        }

        ScrollView(showsIndicators: false) {
          VStack(spacing: 24) {
            MoneyWeekSelector(title: currentWeekTitle, onPrevious: {
              selectedDate = selectedDate.addingMoneyJarWeeks(-1)
            }, onNext: {
              selectedDate = selectedDate.addingMoneyJarWeeks(1)
            }, onTap: {
              showWeekCalendar()
            })
            MoneyBudgetCard(mode: budgetMode, progress: progress, limit: limit) {
              withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                budgetMode = budgetMode == "expense" ? "income" : "expense"
              }
            }
            MoneyStatCards(expense: totalExpense, income: totalIncome)
            MoneyTransactionList(transactions: transactions)
          }
          .padding(.horizontal, 24)
          .padding(.top, 0)
          .padding(.bottom, 80)
        }
      }
    }
    .ignoresSafeArea()
  }

  private func showMoneySettings() {
    guard !showSettings else { return }
    showSettings = true
    BottomSheetCenter.shared.showCenter(onHide: {
      showSettings = false
    }) {
      MoneySettingsSheet(
        budgetMode: $budgetMode,
        budgetLimit: $budgetLimit,
        incomeGoal: $incomeGoal
      )
    }
  }

  private func showWeekCalendar() {
    guard !showWeekPicker else { return }
    showWeekPicker = true
    BottomSheetCenter.shared.show(onHide: {
      showWeekPicker = false
    }) {
      MoneyWeekPickerSheet(
        selectedDate: $selectedDate,
        budgetMode: budgetMode
      )
    }
  }
}
