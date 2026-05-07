import SwiftUI

struct MoneyJarView: View {
  @State private var budgetMode = "expense"
  @State private var showSettings = false
  @State private var selectedDate = Date.mishuMoneyJarSeed
  @State private var showWeekPicker = false
  @State private var budgetLimit = 500
  @State private var incomeGoal = 1000
  @StateObject private var viewModel = MoneyJarViewModel()

  private var limit: Int {
    budgetMode == "expense" ? budgetLimit : incomeGoal
  }

  private var progress: Double {
    guard limit > 0 else { return 0 }
    return Double(budgetMode == "expense" ? viewModel.totalExpense : viewModel.totalIncome) / Double(limit)
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
            MoneyStatCards(expense: viewModel.totalExpense, income: viewModel.totalIncome)
            MoneyTransactionList(transactions: viewModel.transactions)
          }
          .padding(.horizontal, 24)
          .padding(.top, 0)
          .padding(.bottom, 80)
        }
      }
    }
    .onAppear {
      viewModel.reload(for: selectedDate)
    }
    .onChange(of: selectedDate) { next in
      viewModel.reload(for: next)
    }
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
    BottomSheetCenter.shared.show(full: true, onHide: {
      showWeekPicker = false
    }) {
      MoneyWeekPickerSheet(
        selectedDate: $selectedDate,
        budgetMode: budgetMode
      )
    }
  }
}
