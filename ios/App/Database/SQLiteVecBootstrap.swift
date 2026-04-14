import Foundation
import SQLite
import SQLite3

enum SQLiteVecBootstrap {
  static func install(on connection: Connection) throws {
    try install(on: connection.handle)
  }

  static func install(on handle: OpaquePointer?) throws {
    var errMsg: UnsafeMutablePointer<CChar>?
    let rc = sqlite3_vec_init(handle, &errMsg, nil)
    guard rc == SQLITE_OK else {
      let message = errMsg.map { String(cString: $0) } ?? "unknown sqlite-vec init error"
      sqlite3_free(errMsg)
      throw SQLiteVecBootstrapError.installationFailed(code: rc, message: message)
    }
  }
}

enum SQLiteVecBootstrapError: Error {
  case installationFailed(code: Int32, message: String)
}

@_silgen_name("sqlite3_vec_init")
private func sqlite3_vec_init(
  _ db: OpaquePointer?,
  _ pzErrMsg: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?,
  _ pApi: UnsafeRawPointer?
) -> Int32
