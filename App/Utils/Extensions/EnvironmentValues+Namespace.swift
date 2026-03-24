import SwiftUI

struct NamespaceKey: EnvironmentKey {
  static let defaultValue: Namespace.ID? = nil
}

extension EnvironmentValues {
  var nsGlobal: Namespace.ID? {
    get {
      self[NamespaceKey.self]
    }
    set {
      self[NamespaceKey.self] = newValue
    }
  }
}
