import Foundation
import SQLite

enum MemoryTable {
  static let table = Table("ai_memories")

  static let id = Expression<Int64>("id")
  static let userId = Expression<String>("user_id")
  static let text = Expression<String>("text")
  static let source = Expression<String>("source")
  static let createdAtMs = Expression<Int64>("created_at_ms")

  static func createIfNeeded(in db: Connection, embeddingDimension: Int) throws {
    try db.run(
      table.create(ifNotExists: true) { t in
        t.column(id, primaryKey: .autoincrement)
        t.column(userId)
        t.column(text)
        t.column(source)
        t.column(createdAtMs)
      }
    )

    try db.run("CREATE INDEX IF NOT EXISTS idx_ai_memories_user_created ON ai_memories(user_id, created_at_ms DESC)")
    try db.run(
      """
      CREATE VIRTUAL TABLE IF NOT EXISTS ai_memories_vec USING vec0(
        embedding float[\(embeddingDimension)]
      );
      """
    )
  }
}

struct MemoryRecord: Equatable {
  let id: Int64
  let userId: String
  let text: String
  let source: String
  let createdAtMs: Int64
  let distance: Double?
}
