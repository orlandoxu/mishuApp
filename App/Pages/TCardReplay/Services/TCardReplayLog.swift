import Foundation

enum TCardReplayLog {
  static func info(_ message: String) {
    #if DEBUG
    print("[TCardReplay] \(message)")
    #endif
  }

  static func error(_ message: String) {
    #if DEBUG
    print("[TCardReplay][Error] \(message)")
    #endif
  }
}
