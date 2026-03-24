import Foundation

protocol Copyable {
  func copy() -> Self
}

extension Copyable where Self: Codable {
  func copy() -> Self? {
    let encoder = JSONEncoder()
    guard let data = try? encoder.encode(self) else { return nil }

    let decoder = JSONDecoder()
    return try? decoder.decode(Self.self, from: data)
  }
}
