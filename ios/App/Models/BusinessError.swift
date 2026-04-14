import Foundation

struct BusinessError: Error {
  let message: String
  let code: Int
  let data: Any?
}

extension BusinessError: LocalizedError {
  var errorDescription: String? {
    message
  }
}
