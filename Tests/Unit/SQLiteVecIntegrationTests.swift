import XCTest
import SQLite3
@testable import MishuApp

final class SQLiteVecIntegrationTests: XCTestCase {
  func testSQLiteVecKNNQueryWorks() throws {
    let dbURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("sqlite-vec-integration")
      .appendingPathExtension("sqlite3")
    _ = try? FileManager.default.removeItem(at: dbURL)

    var db: OpaquePointer?
    XCTAssertEqual(sqlite3_open(dbURL.path, &db), SQLITE_OK)
    defer {
      sqlite3_close(db)
      try? FileManager.default.removeItem(at: dbURL)
    }

    guard let db else {
      XCTFail("Failed to open sqlite database")
      return
    }

    try SQLiteVecBootstrap.install(on: db)

    XCTAssertFalse(try scalarText("SELECT vec_version();", db: db).isEmpty)

    try exec(
      """
      CREATE VIRTUAL TABLE vec_items USING vec0(
        embedding float[3],
        label text
      );
      """,
      db: db
    )

    try exec(
      """
      INSERT INTO vec_items(rowid, embedding, label) VALUES
        (1, '[1, 0, 0]', 'x'),
        (2, '[0, 1, 0]', 'y'),
        (3, '[0, 0, 1]', 'z');
      """,
      db: db
    )

    let top2 = try queryRowIds(
      """
      SELECT rowid
      FROM vec_items
      WHERE embedding MATCH '[0.95, 0.05, 0.0]' AND k = 2
      ORDER BY distance;
      """,
      db: db
    )

    XCTAssertEqual(top2, [1, 2])
  }

  private func exec(_ sql: String, db: OpaquePointer) throws {
    var errMsg: UnsafeMutablePointer<CChar>?
    let rc = sqlite3_exec(db, sql, nil, nil, &errMsg)
    guard rc == SQLITE_OK else {
      let msg = errMsg.map(String.init(cString:)) ?? "sqlite3_exec failed with code \(rc)"
      sqlite3_free(errMsg)
      throw NSError(domain: "SQLiteVecIntegrationTests", code: Int(rc), userInfo: [NSLocalizedDescriptionKey: msg])
    }
  }

  private func scalarText(_ sql: String, db: OpaquePointer) throws -> String {
    var stmt: OpaquePointer?
    defer { sqlite3_finalize(stmt) }

    let prepareCode = sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
    guard prepareCode == SQLITE_OK else {
      throw NSError(domain: "SQLiteVecIntegrationTests", code: Int(prepareCode), userInfo: nil)
    }

    guard sqlite3_step(stmt) == SQLITE_ROW else {
      throw NSError(domain: "SQLiteVecIntegrationTests", code: 0, userInfo: nil)
    }

    guard let text = sqlite3_column_text(stmt, 0) else { return "" }
    return String(cString: text)
  }

  private func queryRowIds(_ sql: String, db: OpaquePointer) throws -> [Int] {
    var stmt: OpaquePointer?
    defer { sqlite3_finalize(stmt) }

    let prepareCode = sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
    guard prepareCode == SQLITE_OK else {
      throw NSError(domain: "SQLiteVecIntegrationTests", code: Int(prepareCode), userInfo: nil)
    }

    var result: [Int] = []
    while sqlite3_step(stmt) == SQLITE_ROW {
      result.append(Int(sqlite3_column_int(stmt, 0)))
    }
    return result
  }
}
