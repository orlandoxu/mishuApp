import Foundation

protocol KeyValueStorage {
  func getString(forKey key: String) async -> String?
  func setString(_ value: String, forKey key: String) async
  func removeValue(forKey key: String) async
  func getData(forKey key: String) async -> Data?
  func setData(_ value: Data, forKey key: String) async
}

// 系统其实存储的东西很少，所以直接使用一个就可以了。如果后续app存储增大，可以考虑拆分
final class UserDefaultsStorage: KeyValueStorage {
  private let defaults: UserDefaults

  init(suiteName: String? = nil) {
    if let suiteName {
      defaults = UserDefaults(suiteName: suiteName) ?? .standard
    } else {
      defaults = .standard
    }
  }

  func getString(forKey key: String) async -> String? {
    defaults.string(forKey: key)
  }

  func setString(_ value: String, forKey key: String) async {
    defaults.set(value, forKey: key)
  }

  func removeValue(forKey key: String) async {
    defaults.removeObject(forKey: key)
  }

  func getData(forKey key: String) async -> Data? {
    defaults.data(forKey: key)
  }

  func setData(_ value: Data, forKey key: String) async {
    defaults.set(value, forKey: key)
  }
}
