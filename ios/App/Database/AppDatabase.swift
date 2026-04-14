import Foundation
import SQLite

final class AppDatabase {
  static let shared = AppDatabase()

  private(set) var db: Connection?
  private(set) var currentUserId: String?

  private init() {}

  func setupIfNeeded(userId: String) throws {
    let normalizedUserId = AppDatabaseConfig.normalizedUserId(userId)
    if db != nil, currentUserId == normalizedUserId { return }

    db = nil
    currentUserId = normalizedUserId

    let fileURL = try AppDatabaseConfig.databaseFileURL(userId: normalizedUserId)

    let connection = try Connection(fileURL.path)
    try SQLiteVecBootstrap.install(on: connection)
    _ = try? connection.run("PRAGMA foreign_keys = OFF")
    _ = try? connection.run("PRAGMA journal_mode = WAL")

    try MemoryTable.createIfNeeded(in: connection, embeddingDimension: AppConst.doubaoEmbeddingDimension)
    db = connection
  }

  func reset() {
    db = nil
    currentUserId = nil
  }
}
