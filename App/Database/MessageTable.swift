import Foundation
import SQLite

enum MessageTable {
  static let table = Table("messages")

  static let id = SQLite.Expression<String>("id")
  static let userId = SQLite.Expression<String>("userId")
  static let title = SQLite.Expression<String>("title")
  static let msgType = SQLite.Expression<String>("msgType")
  static let subType = SQLite.Expression<Int>("subType")
  static let status = SQLite.Expression<Int>("status") // 1-未读，2-已读
  static let coverUrl = SQLite.Expression<String>("coverUrl")
  static let mediaUrl = SQLite.Expression<String>("mediaUrl")
  static let schema = SQLite.Expression<String>("schema")
  static let imei = SQLite.Expression<String>("imei")
  static let createAt = SQLite.Expression<Int>("createAt")
  static let updateAt = SQLite.Expression<Int>("updateAt")
  static let mediaStatus = SQLite.Expression<Int>("mediaStatus")

  static func createIfNeeded(in db: Connection) throws {
    try db.run(table.create(ifNotExists: true) { t in
      t.column(id, primaryKey: true)
      t.column(userId)
      t.column(title)
      t.column(msgType)
      t.column(subType)
      t.column(status)
      t.column(coverUrl)
      t.column(mediaUrl)
      t.column(schema)
      t.column(imei, defaultValue: "")
      t.column(createAt)
      t.column(updateAt)
      t.column(mediaStatus)
    })

    try db.run(table.createIndex(msgType, updateAt, ifNotExists: true))
    try ensureColumn(db, column: "imei", defaultValue: "''")
  }

  static func fetchAll() -> [MessageModel] {
    guard let db = AppDatabase.shared.db else { return [] }
    do {
      let rows = try db.prepare(table.order(updateAt.desc))
      return rows.map { row in
        MessageModel(
          id: row[id],
          userId: row[userId],
          title: row[title],
          msgType: row[msgType],
          subType: row[subType],
          status: row[status],
          coverUrl: row[coverUrl],
          mediaUrl: row[mediaUrl],
          schema: row[schema],
          createAt: row[createAt],
          updateAt: row[updateAt],
          mediaStatus: row[mediaStatus],
          imei: row[imei]
        )
      }
    } catch {
      return []
    }
  }

  static func upsert(_ messages: [MessageModel], in db: Connection) throws {
    try db.transaction {
      for msg in messages {
        try db.run(
          table.insert(
            or: .replace,
            id <- msg.id,
            userId <- msg.userId,
            title <- msg.title,
            msgType <- msg.msgType,
            subType <- msg.subType,
            status <- msg.status,
            coverUrl <- msg.coverUrl,
            mediaUrl <- msg.mediaUrl,
            schema <- msg.schema,
            imei <- msg.imei,
            createAt <- msg.createAt,
            updateAt <- msg.updateAt,
            mediaStatus <- msg.mediaStatus
          )
        )
      }
    }
  }

  static func delete(_ ids: [String], in db: Connection) throws {
    if ids.isEmpty { return }
    let filter = table.filter(ids.contains(id))
    try db.run(filter.delete())
  }

  static func markAllAsRead(in db: Connection) throws {
    let update = table.update(status <- 2)
    try db.run(update)
  }

  static func markAsRead(_ ids: [String], in db: Connection) throws {
    if ids.isEmpty { return }
    let filter = table.filter(ids.contains(id))
    try db.run(filter.update(status <- 2))
  }

  private static func ensureColumn(_ db: Connection, column: String, defaultValue: String) throws {
    if hasColumn(db, column: column) { return }
    try db.run("ALTER TABLE messages ADD COLUMN \(column) TEXT DEFAULT \(defaultValue)")
  }

  private static func hasColumn(_ db: Connection, column: String) -> Bool {
    do {
      let rows = try db.prepare("PRAGMA table_info(messages)")
      for row in rows {
        if let name = row[1] as? String, name == column {
          return true
        }
      }
    } catch {
      return false
    }
    return false
  }
}
