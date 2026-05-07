import Foundation

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
