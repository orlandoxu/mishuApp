import Foundation
import UIKit

enum UmengService {
  private static var isEnabled: Bool = false
  private static var currentUserId: String = ""

  static func setup(appKey: String, channel: String, logEnabled: Bool) {
    let trimmedKey = appKey.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedKey.isEmpty else { return }

    UMConfigure.setLogEnabled(logEnabled)

    let config = UMAPMConfig.default()
    // 核心诉求：优先保证崩溃/卡顿监控开启
    config.crashAndBlockMonitorEnable = true
    config.launchMonitorEnable = true
    config.memMonitorEnable = true
    config.oomMonitorEnable = true
    UMCrashConfigure.setAPMConfig(config)

    let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    let buildVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
    UMCrashConfigure.setAppVersion(shortVersion ?? "0.0.0", buildVersion: buildVersion)

    UMConfigure.initWithAppkey(trimmedKey, channel: channel)
    UMCrashConfigure.setCrashCallBack { _ in
      let trimmedUserId = self.currentUserId.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmedUserId.isEmpty else { return nil }
      return "uid=\(trimmedUserId)"
    }
    isEnabled = true
  }

  static func trackEvent(_ name: String, properties: [String: String]? = nil) {
    guard isEnabled else { return }
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    if let properties, !properties.isEmpty {
      MobClick.event(trimmed, attributes: properties)
    } else {
      MobClick.event(trimmed)
    }
  }

  static func beginPage(_ name: String) {
    guard isEnabled else { return }
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    MobClick.beginLogPageView(trimmed)
  }

  static func endPage(_ name: String) {
    guard isEnabled else { return }
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    MobClick.endLogPageView(trimmed)
  }

  static func login(userId: String) {
    guard isEnabled else { return }
    let trimmed = userId.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    currentUserId = trimmed
    MobClick.profileSignIn(withPUID: trimmed)
  }

  static func logout() {
    guard isEnabled else { return }
    currentUserId = ""
    MobClick.profileSignOff()
  }
}

// MARK: - App Log Service

enum AppLogUploadTrigger {
  case manual
  case remote(taskId: String?)
}

struct AppLogUploadResult {
  let success: Bool
  let url: String?
  let key: String?
  let reason: String?
}

/// 全局统一日志函数
/// 用法：
/// - `LKLog("启动成功")`
/// - `LKLog(error, type: "network", label: "error")`
func LKLog(_ data: Any, type: String = "default", label: String = "info") {
  AppLogService.shared.log(data, type: type, label: label)
}

final class AppLogService {
  static let shared = AppLogService()

  private let store = AppLogStore()
  private let maxFileBytes = 1024 * 1024 // 1MB
  private let uploadCapBytes = 1_000_000 // 兼容服务端限制，上传时最多带 100w 字节

  private init() {}

  func setup() {
    Task {
      await store.prepare()
      await store.importFallbackCrashIfNeeded(maxBytes: maxFileBytes)
      await store.trimIfNeeded(maxBytes: maxFileBytes)
    }
    LKLog("log service setup", type: "app", label: "info")
  }

  func log(_ data: Any, type: String = "any type", label: String = "info") {
    let text = String(describing: data).trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty else { return }
    let safeType = type.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "any type" : type
    let safeLabel = label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "info" : label
    Task {
      await store.append(
        label: safeLabel,
        type: safeType,
        payload: text,
        maxBytes: maxFileBytes
      )
    }
    #if DEBUG
      let now = Self.consoleTimestamp.string(from: Date())
      print("[\(now) \(safeType)] \(text)")
    #endif
  }

  func uploadCurrentLog(trigger: AppLogUploadTrigger) async -> AppLogUploadResult {
    let triggerText: String
    switch trigger {
    case .manual:
      triggerText = "manual"
    case let .remote(taskId):
      triggerText = "remote:\(taskId ?? "-")"
    }
    LKLog("upload start trigger=\(triggerText)", type: "upload", label: "info")

    let payload = await store.snapshot(maxBytes: uploadCapBytes)
    guard !payload.isEmpty else {
      LKLog("upload skipped: empty log", type: "upload", label: "warning")
      return AppLogUploadResult(success: false, url: nil, key: nil, reason: "日志为空")
    }

    guard let token = await ResourceAPI.shared.getLogUploadToken() else {
      LKLog("upload failed: token unavailable", type: "upload", label: "error")
      return AppLogUploadResult(success: false, url: nil, key: nil, reason: "获取上传凭证失败")
    }

    let fileName = "ios-app-log-\(Self.fileTimestamp.string(from: Date())).log"
    guard let key = await UploadAPI.shared.uploadData2QiNiu(
      data: payload,
      mime: "text/plain",
      fileName: fileName,
      token: token
    ) else {
      LKLog("upload failed: qiniu upload error", type: "upload", label: "error")
      return AppLogUploadResult(success: false, url: nil, key: nil, reason: "上传失败")
    }

    let url = token.baseUrl.removeTrailingSlash + "/" + key
    LKLog("upload success url=\(url)", type: "upload", label: "info")
    return AppLogUploadResult(success: true, url: url, key: key, reason: nil)
  }

  func fetchRecentText(maxBytes: Int = 8192) async -> String {
    await store.latestText(maxBytes: maxBytes)
  }

  private static let fileTimestamp: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyyMMdd-HHmmss"
    return formatter
  }()

  private static let consoleTimestamp: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "MM/dd HH:mm:ss.SSS"
    return formatter
  }()
}

actor AppLogStore {
  private let fileManager = FileManager.default
  private let datetimeFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "MM/dd HH:mm:ss.SSS"
    return f
  }()

  private var cachedLogURL: URL?

  func prepare() {
    _ = ensureLogFileURL()
  }

  func append(
    label: String,
    type: String,
    payload: String,
    maxBytes: Int
  ) {
    _ = label
    guard let url = ensureLogFileURL() else { return }

    let timestamp = datetimeFormatter.string(from: Date())
    let line = "[\(timestamp) \(type)] \(payload)\n"
    guard let lineData = line.data(using: .utf8) else { return }

    if let handle = try? FileHandle(forWritingTo: url) {
      defer { try? handle.close() }
      do {
        try handle.seekToEnd()
      } catch {
        handle.seekToEndOfFile()
      }
      do {
        try handle.write(contentsOf: lineData)
      } catch {
        handle.write(lineData)
      }
    } else {
      try? lineData.write(to: url, options: .atomic)
    }

    trimIfNeeded(maxBytes: maxBytes)
  }

  func trimIfNeeded(maxBytes: Int) {
    guard let url = ensureLogFileURL() else { return }
    guard let attrs = try? fileManager.attributesOfItem(atPath: url.path),
          let sizeNum = attrs[.size] as? NSNumber else { return }
    let size = sizeNum.intValue
    if size <= maxBytes { return }

    guard let data = try? Data(contentsOf: url) else { return }
    let keepSize = max(0, Int(Double(maxBytes) * 0.75))
    let suffixData = data.suffix(keepSize)
    var merged = Data()
    if let marker = "\n--- LOG TRIMMED: keep last \(keepSize) bytes ---\n".data(using: .utf8) {
      merged.append(marker)
    }
    merged.append(suffixData)
    try? merged.write(to: url, options: .atomic)
  }

  func snapshot(maxBytes: Int) -> Data {
    guard let url = ensureLogFileURL(), let data = try? Data(contentsOf: url) else {
      return Data()
    }
    if data.count <= maxBytes { return data }
    return Data(data.suffix(maxBytes))
  }

  func latestText(maxBytes: Int) -> String {
    let data = snapshot(maxBytes: maxBytes)
    return String(data: data, encoding: .utf8) ?? ""
  }

  func importFallbackCrashIfNeeded(maxBytes: Int) {
    guard let fallbackURL = fallbackCrashURL() else { return }
    guard fileManager.fileExists(atPath: fallbackURL.path) else { return }
    guard let crashData = try? Data(contentsOf: fallbackURL), !crashData.isEmpty else { return }
    let crashText = String(data: crashData, encoding: .utf8) ?? "<binary crash fallback>"
    append(
      label: "error",
      type: "crash",
      payload: "recovered crash fallback content=\(truncateText(crashText, limit: 2000))",
      maxBytes: maxBytes
    )
    try? fileManager.removeItem(at: fallbackURL)
  }

  private func ensureLogFileURL() -> URL? {
    if let cachedLogURL { return cachedLogURL }
    guard let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
      return nil
    }
    let dir = caches.appendingPathComponent("tuyun-logs", isDirectory: true)
    if !fileManager.fileExists(atPath: dir.path) {
      try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
    }
    let fileURL = dir.appendingPathComponent("app.log")
    if !fileManager.fileExists(atPath: fileURL.path) {
      fileManager.createFile(atPath: fileURL.path, contents: nil)
    }
    cachedLogURL = fileURL
    return fileURL
  }

  private func fallbackCrashURL() -> URL? {
    guard let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
      return nil
    }
    return caches.appendingPathComponent("tuyun-logs/crash_fallback.log")
  }

  private func truncateText(_ text: String, limit: Int) -> String {
    if text.count <= limit { return text }
    let index = text.index(text.startIndex, offsetBy: limit)
    return String(text[..<index]) + "...<truncated>"
  }
}

// MARK: - Crash Monitor

// 先不要崩溃这个，因为友盟已经拦截了崩溃了
// final class AppCrashMonitor {
//   static let shared = AppCrashMonitor()
//   private init() {}

//   func install() {
//     NSSetUncaughtExceptionHandler { exception in
//       let reason = exception.reason ?? "unknown"
//       let name = exception.name.rawValue
//       let stack = exception.callStackSymbols.joined(separator: "\n")
//       Self.persistCrashFallback(
//         "uncaught exception name=\(name) reason=\(reason)\nstack=\n\(stack)\n"
//       )
//       LKLog(
//         "uncaught exception name=\(name) reason=\(reason) stack=\(stack.prefix(1200))",
//         type: "crash",
//         label: "error"
//       )
//     }
//   }

//   private static func persistCrashFallback(_ text: String) {
//     guard let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return }
//     let url = caches.appendingPathComponent("tuyun-logs/crash_fallback.log")
//     let header = "time=\(Date())\n"
//     let payload = header + text + "\n"
//     if let data = payload.data(using: .utf8) {
//       if FileManager.default.fileExists(atPath: url.path),
//          let handle = try? FileHandle(forWritingTo: url)
//       {
//         defer { try? handle.close() }
//         do {
//           try handle.seekToEnd()
//         } catch {
//           handle.seekToEndOfFile()
//         }
//         do {
//           try handle.write(contentsOf: data)
//         } catch {
//           handle.write(data)
//         }
//       } else {
//         let dir = url.deletingLastPathComponent()
//         try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
//         FileManager.default.createFile(atPath: url.path, contents: data)
//       }
//     }
//   }
// }
