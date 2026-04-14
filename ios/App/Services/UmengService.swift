import Foundation

enum UmengService {
  static func setup(appKey _: String, channel _: String, logEnabled _: Bool) {}
  static func login(userId _: String) {}
  static func logout() {}
  static func event(_ _: String, attributes _: [String: String]? = nil) {}
}

enum AppLogUploadTrigger {
  case manual
}

func LKLog(_ data: Any, type: String = "default", label: String = "info") {
  AppLogService.shared.append(data: data, type: type, label: label)
}

final class AppLogService {
  static let shared = AppLogService()

  private let queue = DispatchQueue(label: "mishu.app.log", qos: .utility)

  private init() {}

  func setup() {}

  func append(data: Any, type: String, label: String) {
    let line = "[\(type)][\(label)] \(String(describing: data))"
    queue.async {
      print(line)
    }
  }

  func upload(trigger _: AppLogUploadTrigger = .manual) async -> Bool {
    true
  }
}
