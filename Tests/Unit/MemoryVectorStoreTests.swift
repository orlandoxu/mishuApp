import XCTest
@testable import MishuApp

final class MemoryVectorStoreTests: XCTestCase {
  override func setUpWithError() throws {
    try super.setUpWithError()
    let userId = "memory_vector_test_user"
    let fileURL = try AppDatabaseConfig.databaseFileURL(userId: AppDatabaseConfig.normalizedUserId(userId))
    try? FileManager.default.removeItem(at: fileURL)
    AppDatabase.shared.reset()
    try AppDatabase.shared.setupIfNeeded(userId: userId)
  }

  override func tearDownWithError() throws {
    AppDatabase.shared.reset()
    try super.tearDownWithError()
  }

  func testInsertAndSearch() throws {
    let userId = "memory_vector_test_user"
    let now = Int64(Date().timeIntervalSince1970 * 1000)

    try MemoryVectorStore.shared.insert(
      userId: userId,
      text: "明天上午去保养",
      source: "test",
      embedding: unitVector(index: 0, dim: AppConst.doubaoEmbeddingDimension),
      createdAtMs: now
    )

    try MemoryVectorStore.shared.insert(
      userId: userId,
      text: "周五晚上买保险",
      source: "test",
      embedding: unitVector(index: 1, dim: AppConst.doubaoEmbeddingDimension),
      createdAtMs: now + 1
    )

    let query = unitVector(index: 0, dim: AppConst.doubaoEmbeddingDimension)
    let rows = try MemoryVectorStore.shared.search(userId: userId, queryEmbedding: query, limit: 2)
    XCTAssertFalse(rows.isEmpty)
    XCTAssertEqual(rows.first?.text, "明天上午去保养")
  }

  private func unitVector(index: Int, dim: Int) -> [Double] {
    var v = Array(repeating: 0.0, count: max(1, dim))
    let idx = max(0, min(v.count - 1, index))
    v[idx] = 1.0
    return v
  }
}
