import Foundation
import SQLite

enum LedgerDirection: String {
  case income
  case expense
}

enum LedgerTable {
  static let table = Table("ledger_transactions")

  static let id = Expression<String>("id")
  static let userId = Expression<String>("user_id")
  static let direction = Expression<String>("direction")
  static let amount = Expression<Double>("amount")
  static let category = Expression<String>("category")
  static let occurredAt = Expression<Int64>("occurred_at")
  static let note = Expression<String?>("note")
  static let createdAt = Expression<Int64>("created_at")
  static let updatedAt = Expression<Int64>("updated_at")

  static func createIfNeeded(in db: Connection) throws {
    try db.run(
      table.create(ifNotExists: true) { t in
        t.column(id, primaryKey: true)
        t.column(userId)
        t.column(direction)
        t.column(amount)
        t.column(category)
        t.column(occurredAt)
        t.column(note)
        t.column(createdAt)
        t.column(updatedAt)
      }
    )

    try db.run("CREATE INDEX IF NOT EXISTS idx_ledger_user_occurred ON ledger_transactions(user_id, occurred_at DESC)")
    try db.run("CREATE INDEX IF NOT EXISTS idx_ledger_user_direction_occurred ON ledger_transactions(user_id, direction, occurred_at DESC)")
    try db.run("CREATE INDEX IF NOT EXISTS idx_ledger_user_category_occurred ON ledger_transactions(user_id, category, occurred_at DESC)")
  }
}

struct LedgerTransactionRecord: Equatable, Identifiable {
  let id: String
  let userId: String
  let direction: LedgerDirection
  let amount: Double
  let category: String
  let occurredAt: Int64
  let note: String?
  let createdAt: Int64
  let updatedAt: Int64
}
