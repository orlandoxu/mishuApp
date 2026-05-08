import Foundation
import SQLite

struct LedgerCreateInput {
  let direction: LedgerDirection
  let amount: Double
  let category: String
  let occurredAt: Int64
  let note: String?
}

struct LedgerQueryFilter {
  let startAtMs: Int64
  let endAtMs: Int64
  let limit: Int
}

struct LedgerSummary {
  let incomeTotal: Double
  let expenseTotal: Double
  let byCategory: [String: Double]
}

actor LedgerLocalService {
  static let shared = LedgerLocalService()

  private init() {}

  func createTransaction(input: LedgerCreateInput) async throws -> LedgerTransactionRecord {
    let userId = try await ensureDatabaseReady()
    let now = Int64(Date().timeIntervalSince1970 * 1000)
    let txId = UUID().uuidString.lowercased()

    guard let db = AppDatabase.shared.db else {
      throw NSError(domain: "LedgerLocalService", code: 500, userInfo: [NSLocalizedDescriptionKey: "database unavailable"])
    }

    try db.run(
      LedgerTable.table.insert(
        LedgerTable.id <- txId,
        LedgerTable.userId <- userId,
        LedgerTable.direction <- input.direction.rawValue,
        LedgerTable.amount <- input.amount,
        LedgerTable.category <- input.category,
        LedgerTable.occurredAt <- input.occurredAt,
        LedgerTable.note <- input.note,
        LedgerTable.createdAt <- now,
        LedgerTable.updatedAt <- now
      )
    )

    return LedgerTransactionRecord(
      id: txId,
      userId: userId,
      direction: input.direction,
      amount: input.amount,
      category: input.category,
      occurredAt: input.occurredAt,
      note: input.note,
      createdAt: now,
      updatedAt: now
    )
  }

  func queryTransactions(filter: LedgerQueryFilter) async throws -> [LedgerTransactionRecord] {
    let userId = try await ensureDatabaseReady()
    guard let db = AppDatabase.shared.db else { return [] }

    let query = LedgerTable.table
      .filter(LedgerTable.userId == userId)
      .filter(LedgerTable.occurredAt >= filter.startAtMs && LedgerTable.occurredAt <= filter.endAtMs)
      .order(LedgerTable.occurredAt.desc)
      .limit(max(1, filter.limit))

    let rows = try db.prepare(query)
    return rows.compactMap(parseRow)
  }

  func querySummary(periodStartMs: Int64, periodEndMs: Int64, groupByCategory: Bool) async throws -> LedgerSummary {
    let items = try await queryTransactions(
      filter: LedgerQueryFilter(startAtMs: periodStartMs, endAtMs: periodEndMs, limit: 5_000)
    )

    let incomeTotal = items
      .filter { $0.direction == .income }
      .map(\.amount)
      .reduce(0, +)

    let expenseTotal = items
      .filter { $0.direction == .expense }
      .map(\.amount)
      .reduce(0, +)

    let byCategory: [String: Double] = groupByCategory
      ? Dictionary(grouping: items.filter { $0.direction == .expense }, by: \.category)
        .mapValues { $0.map(\.amount).reduce(0, +) }
      : [:]

    return LedgerSummary(incomeTotal: incomeTotal, expenseTotal: expenseTotal, byCategory: byCategory)
  }

  private func parseRow(_ row: Row) -> LedgerTransactionRecord? {
    guard let parsedDirection = LedgerDirection(rawValue: row[LedgerTable.direction]) else {
      return nil
    }

    return LedgerTransactionRecord(
      id: row[LedgerTable.id],
      userId: row[LedgerTable.userId],
      direction: parsedDirection,
      amount: row[LedgerTable.amount],
      category: row[LedgerTable.category],
      occurredAt: row[LedgerTable.occurredAt],
      note: row[LedgerTable.note],
      createdAt: row[LedgerTable.createdAt],
      updatedAt: row[LedgerTable.updatedAt]
    )
  }

  private func ensureDatabaseReady() async throws -> String {
    let userId = await MainActor.run {
      SelfStore.shared.selfUser?.userId ?? "guest"
    }
    try AppDatabase.shared.setupIfNeeded(userId: userId)
    return userId
  }
}
