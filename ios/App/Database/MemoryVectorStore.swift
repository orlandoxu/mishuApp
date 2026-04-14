import Foundation
import SQLite
import SQLite3

final class MemoryVectorStore {
  static let shared = MemoryVectorStore()

  private init() {}

  func insert(
    userId: String,
    text: String,
    source: String,
    embedding: [Double],
    createdAtMs: Int64
  ) throws {
    guard let db = AppDatabase.shared.db else { return }
    let textValue = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !textValue.isEmpty, !embedding.isEmpty else { return }

    let insert = MemoryTable.table.insert(
      MemoryTable.userId <- userId,
      MemoryTable.text <- textValue,
      MemoryTable.source <- source,
      MemoryTable.createdAtMs <- createdAtMs
    )
    let rowId = try db.run(insert)
    try upsertEmbedding(rowId: rowId, embedding: embedding, db: db)
  }

  func search(
    userId: String,
    queryEmbedding: [Double],
    limit: Int
  ) throws -> [MemoryRecord] {
    guard let db = AppDatabase.shared.db else { return [] }
    guard !queryEmbedding.isEmpty else { return [] }
    let idsWithDistance = try matchVector(queryEmbedding: queryEmbedding, limit: limit, db: db)
    guard !idsWithDistance.isEmpty else { return [] }

    let distanceMap = Dictionary(uniqueKeysWithValues: idsWithDistance.map { ($0.id, $0.distance) })
    let metadata = try fetchMetadata(userId: userId, ids: idsWithDistance.map(\.id), db: db)
    return metadata
      .map {
        MemoryRecord(
          id: $0.id,
          userId: $0.userId,
          text: $0.text,
          source: $0.source,
          createdAtMs: $0.createdAtMs,
          distance: distanceMap[$0.id]
        )
      }
    .sorted { lhs, rhs in
      (lhs.distance ?? .greatestFiniteMagnitude) < (rhs.distance ?? .greatestFiniteMagnitude)
    }
  }

  private func upsertEmbedding(rowId: Int64, embedding: [Double], db: Connection) throws {
    let vectorText = vectorLiteral(embedding)
    let sql = "INSERT OR REPLACE INTO ai_memories_vec(rowid, embedding) VALUES (?, ?);"

    let handle = db.handle
    var stmt: OpaquePointer?
    defer { sqlite3_finalize(stmt) }

    let prepareRc = sqlite3_prepare_v2(handle, sql, -1, &stmt, nil)
    guard prepareRc == SQLITE_OK else {
      throw sqliteError(db: handle, code: prepareRc, fallback: "prepare failed for insert embedding")
    }

    sqlite3_bind_int64(stmt, 1, rowId)
    sqlite3_bind_text(stmt, 2, (vectorText as NSString).utf8String, -1, SQLITE_TRANSIENT)

    let step = sqlite3_step(stmt)
    guard step == SQLITE_DONE else {
      throw sqliteError(db: handle, code: step, fallback: "insert embedding failed")
    }
  }

  private func matchVector(queryEmbedding: [Double], limit: Int, db: Connection) throws -> [(id: Int64, distance: Double)] {
    let k = max(1, min(20, limit))
    let sql = """
    SELECT rowid, distance
    FROM ai_memories_vec
    WHERE embedding MATCH ? AND k = ?
    ORDER BY distance;
    """
    let handle = db.handle
    var stmt: OpaquePointer?
    defer { sqlite3_finalize(stmt) }

    let prepareRc = sqlite3_prepare_v2(handle, sql, -1, &stmt, nil)
    guard prepareRc == SQLITE_OK else {
      throw sqliteError(db: handle, code: prepareRc, fallback: "prepare failed for match vector")
    }

    let query = vectorLiteral(queryEmbedding)
    sqlite3_bind_text(stmt, 1, (query as NSString).utf8String, -1, SQLITE_TRANSIENT)
    sqlite3_bind_int(stmt, 2, Int32(k))
    var result: [(id: Int64, distance: Double)] = []
    while sqlite3_step(stmt) == SQLITE_ROW {
      let id = sqlite3_column_int64(stmt, 0)
      let distance = sqlite3_column_double(stmt, 1)
      result.append((id, distance))
    }
    return result
  }

  private func fetchMetadata(userId: String, ids: [Int64], db: Connection) throws -> [MemoryRecord] {
    guard !ids.isEmpty else { return [] }
    let placeholders = ids.map { _ in "?" }.joined(separator: ",")
    let sql = """
    SELECT id, user_id, text, source, created_at_ms
    FROM ai_memories
    WHERE user_id = ? AND id IN (\(placeholders));
    """
    let handle = db.handle
    var stmt: OpaquePointer?
    defer { sqlite3_finalize(stmt) }

    let prepareRc = sqlite3_prepare_v2(handle, sql, -1, &stmt, nil)
    guard prepareRc == SQLITE_OK else {
      throw sqliteError(db: handle, code: prepareRc, fallback: "prepare failed for metadata query")
    }

    sqlite3_bind_text(stmt, 1, (userId as NSString).utf8String, -1, SQLITE_TRANSIENT)
    for (index, id) in ids.enumerated() {
      sqlite3_bind_int64(stmt, Int32(index + 2), id)
    }

    var rows: [MemoryRecord] = []
    while sqlite3_step(stmt) == SQLITE_ROW {
      let id = sqlite3_column_int64(stmt, 0)
      let userIdText = sqlite3_column_text(stmt, 1).map { String(cString: $0) } ?? ""
      let text = sqlite3_column_text(stmt, 2).map { String(cString: $0) } ?? ""
      let source = sqlite3_column_text(stmt, 3).map { String(cString: $0) } ?? ""
      let createdAtMs = sqlite3_column_int64(stmt, 4)
      rows.append(
        MemoryRecord(
          id: id,
          userId: userIdText,
          text: text,
          source: source,
          createdAtMs: createdAtMs,
          distance: nil
        )
      )
    }
    return rows
  }

  private func vectorLiteral(_ values: [Double]) -> String {
    let body = values.map { String($0) }.joined(separator: ", ")
    return "[\(body)]"
  }

  private func sqliteError(db: OpaquePointer, code: Int32, fallback: String) -> NSError {
    let cmsg = sqlite3_errmsg(db).map { String(cString: $0) } ?? fallback
    return NSError(domain: "MemoryVectorStore", code: Int(code), userInfo: [NSLocalizedDescriptionKey: cmsg])
  }
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
