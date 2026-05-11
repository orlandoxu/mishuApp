import SwiftUI

private struct LedgerQueryItemDTO: Codable {
  let id: String
  let direction: String
  let amount: Double
  let category: String
  let note: String?
  let occurredAt: Int64
}

private struct LedgerQueryDTO: Codable {
  let items: [LedgerQueryItemDTO]
}

private struct MoneyCategoryDTO: Codable, Identifiable {
  let id: String
  let direction: String
  let name: String
  let canEdit: Bool
  let deleted: Bool
  let sort: Int
}

private struct MoneyCategoryListDTO: Codable {
  let expense: [MoneyCategoryDTO]
  let income: [MoneyCategoryDTO]
}

private struct MoneyCategorySaveDTO: Codable {
  let items: [MoneyCategoryDTO]
}

private struct MoneyCategorySaveBody: Codable {
  let direction: String
  let names: [String]
}

private enum MoneyJarRemoteAPI {
  static func query(startAtMs: Int64, endAtMs: Int64, limit: Int = 200) async -> LedgerQueryDTO? {
    await APIClient().postRequest(
      "/ledger/query",
      AnyParams([
        "startAtMs": startAtMs,
        "endAtMs": endAtMs,
        "limit": Int64(max(1, min(500, limit))),
      ]),
      true,
      false
    )
  }

  static func categories() async -> MoneyCategoryListDTO? {
    await APIClient().getRequest("/ledger/categories", Empty(), true, false)
  }

  static func saveCategories(direction: String, names: [String]) async -> MoneyCategorySaveDTO? {
    await APIClient().postRequest(
      "/ledger/categories/save",
      MoneyCategorySaveBody(direction: direction, names: names),
      true,
      false
    )
  }
}

struct MoneyJarView: View {
  private static let defaultExpenseCategories = ["餐饮", "交通", "购物", "娱乐", "居住", "教育", "医疗", "其他"]
  private static let defaultIncomeCategories = ["工资", "兼职", "理财", "红包", "其他"]
  @State private var budgetMode = "expense"
  @State private var showSettings = false
  @State private var selectedDate = Date()
  @State private var showWeekPicker = false
  @State private var budgetLimit = 500
  @State private var incomeGoal = 1000
  @State private var expenseCategories: [EditableMoneyCategory] = MoneyJarView.defaultExpenseCategories.enumerated().map {
    EditableMoneyCategory(id: "expense-\($0.offset)", name: $0.element, canEdit: $0.element != "其他")
  }
  @State private var incomeCategories: [EditableMoneyCategory] = MoneyJarView.defaultIncomeCategories.enumerated().map {
    EditableMoneyCategory(id: "income-\($0.offset)", name: $0.element, canEdit: $0.element != "其他")
  }
  @State private var showCategorySettings = false
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
          Menu {
            Button {
              showMoneySettings()
            } label: {
              Label("收支设置", systemImage: "slider.horizontal.3")
            }

            Button {
              showCategorySettingsSheet()
            } label: {
              Label("分类设置", systemImage: "tag")
            }
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
      Task { await loadCategories() }
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

  private func loadCategories() async {
    guard let data = await MoneyJarRemoteAPI.categories() else { return }
    let expense = data.expense.filter { !$0.deleted }.map {
      EditableMoneyCategory(id: $0.id, name: $0.name, canEdit: $0.canEdit)
    }
    let income = data.income.filter { !$0.deleted }.map {
      EditableMoneyCategory(id: $0.id, name: $0.name, canEdit: $0.canEdit)
    }
    if !expense.isEmpty {
      expenseCategories = expense
    }
    if !income.isEmpty {
      incomeCategories = income
    }
  }

  private func showCategorySettingsSheet() {
    guard !showCategorySettings else { return }
    showCategorySettings = true
    BottomSheetCenter.shared.showCenter(onHide: {
      showCategorySettings = false
    }) {
      MoneyCategorySettingsSheet(
        expenseCategories: $expenseCategories,
        incomeCategories: $incomeCategories,
        onSave: { nextExpense, nextIncome in
          Task {
            _ = await MoneyJarRemoteAPI.saveCategories(
              direction: "expense",
              names: nextExpense.map(\.name)
            )
            _ = await MoneyJarRemoteAPI.saveCategories(
              direction: "income",
              names: nextIncome.map(\.name)
            )
            await loadCategories()
          }
        }
      )
    }
  }
}

@MainActor
final class MoneyJarViewModel: ObservableObject {
  @Published private(set) var transactions: [MoneyTransaction] = []
  @Published private(set) var totalIncome: Int = 0
  @Published private(set) var totalExpense: Int = 0

  func reload(for selectedDate: Date) {
    Task {
      await loadWeekData(selectedDate: selectedDate)
    }
  }

  private func loadWeekData(selectedDate: Date) async {
    let weekStart = selectedDate.moneyJarWeekStart
    let weekEnd = Calendar.moneyJar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
    let startMs = Int64(weekStart.timeIntervalSince1970 * 1000)
    let endMs = Int64(weekEnd.timeIntervalSince1970 * 1000) - 1

    if let remoteQuery = await MoneyJarRemoteAPI.query(startAtMs: startMs, endAtMs: endMs, limit: 200) {
      var incomeTotal = 0
      var expenseTotal = 0
      transactions = remoteQuery.items.map { item in
        if item.direction == "income" {
          incomeTotal += Int(item.amount.rounded())
        } else {
          expenseTotal += Int(item.amount.rounded())
        }
        return MoneyTransaction(
          id: item.id,
          type: item.direction,
          amount: Int(item.amount.rounded()),
          category: item.category,
          date: formatDate(item.occurredAt),
          note: item.note?.isEmpty == false ? item.note! : "服务端记账"
        )
      }
      totalIncome = incomeTotal
      totalExpense = expenseTotal
      return
    }

    // 兜底：接口异常时回退本地数据，避免空白页面
    do {
      let localItems = try await LedgerLocalService.shared.queryTransactions(
        filter: LedgerQueryFilter(startAtMs: startMs, endAtMs: endMs, limit: 200)
      )
      let summary = try await LedgerLocalService.shared.querySummary(
        periodStartMs: startMs,
        periodEndMs: endMs,
        groupByCategory: true
      )
      transactions = localItems.map { item in
        MoneyTransaction(
          id: item.id,
          type: item.direction.rawValue,
          amount: Int(item.amount.rounded()),
          category: item.category,
          date: formatDate(item.occurredAt),
          note: item.note?.isEmpty == false ? item.note! : "本地记账"
        )
      }
      totalIncome = Int(summary.incomeTotal.rounded())
      totalExpense = Int(summary.expenseTotal.rounded())
    } catch {
      transactions = []
      totalIncome = 0
      totalExpense = 0
    }
  }

  private func formatDate(_ timestampMs: Int64) -> String {
    let date = Date(timeIntervalSince1970: TimeInterval(timestampMs) / 1000)
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
  }
}
