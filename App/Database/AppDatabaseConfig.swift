import Foundation

enum AppDatabaseConfig {
  static func databaseDirectoryURL() throws -> URL {
    let fm = FileManager.default
    let base = try fm.url(
      for: .applicationSupportDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    )
    let dir = base.appendingPathComponent("TuYun", isDirectory: true)
    if !fm.fileExists(atPath: dir.path) {
      try fm.createDirectory(at: dir, withIntermediateDirectories: true)
    }
    return dir
  }

  static func sharedDatabaseFileURL() throws -> URL {
    let dir = try databaseDirectoryURL()
    return dir.appendingPathComponent("app.sqlite3", isDirectory: false)
  }

  /// 根据用户名，获取对应的数据库
  static func databaseFileURL(userId: String) throws -> URL {
    let dir = try databaseDirectoryURL()
    return dir.appendingPathComponent("user_\(userId).sqlite3", isDirectory: false)
  }

  static func normalizedUserId(_ raw: String) -> String {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return "unknown" }
    let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_")
    return String(trimmed.unicodeScalars.map { allowed.contains($0) ? Character(String($0)) : "_" })
  }
}
