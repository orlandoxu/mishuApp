import Foundation

extension Array {
  func rotated(by amount: Int) -> [Element] {
    guard count > 0 else { return self }
    let amount = (amount % count + count) % count
    return Array(self[amount..<count] + self[0..<amount])
  }
}
