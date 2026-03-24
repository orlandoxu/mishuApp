import AVFoundation
import Foundation
import Photos
import SwiftUI
import UIKit

enum LocalVideoSaveResult {
  case success
  case failed(String)
}

@MainActor
final class LocalAlbumStore: ObservableObject {
  static let shared = LocalAlbumStore()

  @Published private(set) var authorization: PHAuthorizationStatus
  @Published private(set) var assets: [PHAsset] = []

  private static let albumTitle = "Mishu AI本地相册"

  private init() {
    authorization = LocalAlbumStore.authorizationStatus()
  }

  var totalCount: Int {
    assets.count
  }

  func refreshIfAuthorized() async {
    authorization = Self.authorizationStatus()
    guard Self.isReadable(authorization) else {
      assets = []
      return
    }
    await refresh()
  }

  func refresh() async {
    authorization = await requestReadAuthorization()
    guard Self.isReadable(authorization) else {
      assets = []
      return
    }

    do {
      let album = try await fetchOrCreateAlbum()
      assets = Self.fetchAssets(in: album)
    } catch {
      assets = []
    }
  }

  func requestReadAuthorization() async -> PHAuthorizationStatus {
    let current = Self.authorizationStatus()
    if current != .notDetermined { return current }
    return await Self.requestAuthorization()
  }

  func save(asset: AlbumAsset) async -> Bool {
    let auth = await requestReadAuthorization()
    authorization = auth
    guard Self.isWritable(auth) else { return false }

    guard let remoteURL = URL(string: asset.url), !asset.url.isEmpty else { return false }

    do {
      let album = try await fetchOrCreateAlbum()
      if asset.mtype == 2 {
        let tempFileURL = try await prepareLocalVideoFile(remote: remoteURL)
        try await saveVideoFileToPhotos(tempFileURL, album: album)
      } else {
        let data = try await downloadData(remote: remoteURL)
        try await saveImageDataToPhotos(data, album: album)
      }
      withAnimation(.easeInOut(duration: 0.25)) {
        assets = Self.fetchAssets(in: album)
      }
      return true
    } catch {
      return false
    }
  }

  func saveImageData(_ data: Data) async -> Bool {
    let auth = await requestReadAuthorization()
    authorization = auth
    guard Self.isWritable(auth) else { return false }
    do {
      let album = try await fetchOrCreateAlbum()
      try await saveImageDataToPhotos(data, album: album)
      withAnimation(.easeInOut(duration: 0.25)) {
        assets = Self.fetchAssets(in: album)
      }
      return true
    } catch {
      return false
    }
  }

  func saveVideoFile(_ fileURL: URL) async -> Bool {
    let result = await saveVideoFileDetailed(fileURL)
    if case let .failed(message) = result {
      Self.log("saveVideoFile failed: \(message)")
      return false
    }
    return true
  }

  func saveVideoFileDetailed(_ fileURL: URL) async -> LocalVideoSaveResult {
    let auth = await requestReadAuthorization()
    authorization = auth
    guard Self.isWritable(auth) else {
      return .failed("相册权限未开启")
    }
    do {
      try validateVideoFile(fileURL)
      let album = try await fetchOrCreateAlbum()
      try await saveVideoFileToPhotos(fileURL, album: album)
      assets = Self.fetchAssets(in: album)
      return .success
    } catch {
      let message = describeVideoSaveError(error, fileURL: fileURL)
      Self.log("saveVideoFile error: \(message)")
      return .failed(message)
    }
  }

  func deleteAssets(localIdentifiers: [String]) async -> Bool {
    guard !localIdentifiers.isEmpty else { return false }

    let auth = await requestReadAuthorization()
    authorization = auth
    guard Self.isWritable(auth) else { return false }

    do {
      guard let album = Self.fetchAlbum() else {
        assets = []
        return true
      }

      let identifiers = Set(localIdentifiers)
      _ = try await performChanges { () -> Bool in
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: Array(identifiers), options: nil)
        guard fetchResult.count > 0 else { return true }
        let changeRequest = PHAssetCollectionChangeRequest(for: album)
        changeRequest?.removeAssets(fetchResult)
        return true
      }

      withAnimation(.easeInOut(duration: 0.25)) {
        assets = Self.fetchAssets(in: album)
      }
      return true
    } catch {
      return false
    }
  }

  private static func authorizationStatus() -> PHAuthorizationStatus {
    if #available(iOS 14, *) {
      return PHPhotoLibrary.authorizationStatus(for: .readWrite)
    } else {
      return PHPhotoLibrary.authorizationStatus()
    }
  }

  private static func requestAuthorization() async -> PHAuthorizationStatus {
    await withCheckedContinuation { continuation in
      if #available(iOS 14, *) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
          DispatchQueue.main.async {
            continuation.resume(returning: status)
          }
        }
      } else {
        PHPhotoLibrary.requestAuthorization { status in
          DispatchQueue.main.async {
            continuation.resume(returning: status)
          }
        }
      }
    }
  }

  private static func isReadable(_ status: PHAuthorizationStatus) -> Bool {
    status == .authorized || status == .limited
  }

  private static func isWritable(_ status: PHAuthorizationStatus) -> Bool {
    status == .authorized || status == .limited
  }

  private func fetchOrCreateAlbum() async throws -> PHAssetCollection {
    if let album = Self.fetchAlbum() { return album }
    return try await createAlbum()
  }

  private static func fetchAlbum() -> PHAssetCollection? {
    let fetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil)
    var found: PHAssetCollection?
    fetchResult.enumerateObjects { collection, _, stop in
      if collection.localizedTitle == Self.albumTitle {
        found = collection
        stop.pointee = true
      }
    }
    return found
  }

  private func createAlbum() async throws -> PHAssetCollection {
    let identifier = try await performChanges { () -> String in
      let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: Self.albumTitle)
      return request.placeholderForCreatedAssetCollection.localIdentifier
    }
    let result = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [identifier], options: nil)
    guard let album = result.firstObject else { throw NSError(domain: "LocalAlbumStore", code: -4) }
    return album
  }

  private static func fetchAssets(in album: PHAssetCollection) -> [PHAsset] {
    let options = PHFetchOptions()
    options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
    let result = PHAsset.fetchAssets(in: album, options: options)
    var assets: [PHAsset] = []
    assets.reserveCapacity(result.count)
    result.enumerateObjects { asset, _, _ in
      assets.append(asset)
    }
    return assets
  }

  private func saveImageDataToPhotos(_ data: Data, album: PHAssetCollection) async throws {
    _ = try await performChanges { () -> Bool in
      let createRequest = PHAssetCreationRequest.forAsset()
      createRequest.addResource(with: .photo, data: data, options: nil)
      guard let placeholder = createRequest.placeholderForCreatedAsset else { return false }
      let changeRequest = PHAssetCollectionChangeRequest(for: album)
      changeRequest?.addAssets([placeholder] as NSArray)
      return true
    }
  }

  private func saveVideoFileToPhotos(_ fileURL: URL, album: PHAssetCollection) async throws {
    _ = try await performChanges { () -> Bool in
      let createRequest = PHAssetCreationRequest.forAsset()
      let options = PHAssetResourceCreationOptions()
      options.shouldMoveFile = true
      createRequest.addResource(with: .video, fileURL: fileURL, options: options)
      guard let placeholder = createRequest.placeholderForCreatedAsset else { return false }
      let changeRequest = PHAssetCollectionChangeRequest(for: album)
      changeRequest?.addAssets([placeholder] as NSArray)
      return true
    }
  }

  private func performChanges<T>(_ changes: @escaping () -> T) async throws -> T {
    try await withCheckedThrowingContinuation { continuation in
      var output: T?
      PHPhotoLibrary.shared().performChanges {
        output = changes()
      } completionHandler: { success, error in
        DispatchQueue.main.async {
          if let error {
            continuation.resume(throwing: error)
            return
          }
          guard success, let output else {
            continuation.resume(throwing: NSError(domain: "LocalAlbumStore", code: -5))
            return
          }
          continuation.resume(returning: output)
        }
      }
    }
  }

  private func downloadData(remote: URL) async throws -> Data {
    try await withCheckedThrowingContinuation { continuation in
      let task = URLSession.shared.dataTask(with: remote) { data, _, error in
        if let error {
          continuation.resume(throwing: error)
          return
        }
        guard let data else {
          continuation.resume(throwing: NSError(domain: "LocalAlbumStore", code: -6))
          return
        }
        continuation.resume(returning: data)
      }
      task.resume()
    }
  }

  private func downloadToTemporaryFile(remote: URL) async throws -> URL {
    try await withCheckedThrowingContinuation { continuation in
      let task = URLSession.shared.downloadTask(with: remote) { url, _, error in
        if let error {
          continuation.resume(throwing: error)
          return
        }
        guard let url else {
          continuation.resume(throwing: NSError(domain: "LocalAlbumStore", code: -7))
          return
        }
        continuation.resume(returning: url)
      }
      task.resume()
    }
  }

  private func prepareLocalVideoFile(remote: URL) async throws -> URL {
    let remoteExt = remote.pathExtension.lowercased()
    if remoteExt == "m3u8" {
      return try await exportVideoToTemporaryFile(remote: remote)
    }

    if ["mp4", "mov", "m4v"].contains(remoteExt) {
      let downloadedURL = try await downloadToTemporaryFile(remote: remote)
      return try copyToTemporaryFileWithExtensionIfNeeded(downloadedURL, preferredExtension: remoteExt)
    }

    let (mimeType, suggestedFilename) = await headRemote(remote: remote)
    if isHLS(mimeType: mimeType) {
      return try await exportVideoToTemporaryFile(remote: remote)
    }

    let downloadedURL = try await downloadToTemporaryFile(remote: remote)
    let preferredExtension =
      normalizedVideoFileExtension(remote: remote, mimeType: mimeType, suggestedFilename: suggestedFilename) ?? "mp4"
    return try copyToTemporaryFileWithExtensionIfNeeded(downloadedURL, preferredExtension: preferredExtension)
  }

  private func headRemote(remote: URL) async -> (mimeType: String?, suggestedFilename: String?) {
    await withCheckedContinuation { continuation in
      var request = URLRequest(url: remote)
      request.httpMethod = "HEAD"
      let task = URLSession.shared.dataTask(with: request) { _, response, _ in
        continuation.resume(returning: (response?.mimeType, response?.suggestedFilename))
      }
      task.resume()
    }
  }

  private func isHLS(mimeType: String?) -> Bool {
    guard let mimeType else { return false }
    let lower = mimeType.lowercased()
    return lower.contains("mpegurl") || lower.contains("application/vnd.apple.mpegurl")
  }

  private func normalizedVideoFileExtension(remote: URL, mimeType: String?, suggestedFilename: String?) -> String? {
    let remoteExt = remote.pathExtension.lowercased()
    if !remoteExt.isEmpty, remoteExt != "m3u8" { return remoteExt }

    if let suggestedFilename {
      let ext = (suggestedFilename as NSString).pathExtension.lowercased()
      if !ext.isEmpty, ext != "m3u8" { return ext }
    }

    guard let mimeType else { return nil }
    switch mimeType.lowercased() {
    case "video/mp4":
      return "mp4"
    case "video/quicktime":
      return "mov"
    case "video/x-m4v":
      return "m4v"
    default:
      return nil
    }
  }

  private func copyToTemporaryFileWithExtensionIfNeeded(_ url: URL, preferredExtension: String) throws -> URL {
    let currentExt = url.pathExtension.lowercased()
    let preferred = preferredExtension.lowercased()
    if currentExt == preferred, !currentExt.isEmpty {
      return url
    }

    let filename = UUID().uuidString + "." + preferred
    let targetURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
    if FileManager.default.fileExists(atPath: targetURL.path) {
      try FileManager.default.removeItem(at: targetURL)
    }
    try FileManager.default.copyItem(at: url, to: targetURL)
    try? FileManager.default.removeItem(at: url)
    return targetURL
  }

  private func exportVideoToTemporaryFile(remote: URL) async throws -> URL {
    let asset = AVURLAsset(url: remote)
    guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
      throw NSError(domain: "LocalAlbumStore", code: -8)
    }

    var outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    if exportSession.supportedFileTypes.contains(.mp4) {
      exportSession.outputFileType = .mp4
      outputURL.appendPathExtension("mp4")
    } else if exportSession.supportedFileTypes.contains(.mov) {
      exportSession.outputFileType = .mov
      outputURL.appendPathExtension("mov")
    } else {
      throw NSError(domain: "LocalAlbumStore", code: -9)
    }

    if FileManager.default.fileExists(atPath: outputURL.path) {
      try FileManager.default.removeItem(at: outputURL)
    }

    exportSession.outputURL = outputURL
    exportSession.shouldOptimizeForNetworkUse = true

    return try await withCheckedThrowingContinuation { continuation in
      exportSession.exportAsynchronously {
        DispatchQueue.main.async {
          switch exportSession.status {
          case .completed:
            continuation.resume(returning: outputURL)
          case .failed:
            continuation.resume(throwing: exportSession.error ?? NSError(domain: "LocalAlbumStore", code: -10))
          case .cancelled:
            continuation.resume(throwing: NSError(domain: "LocalAlbumStore", code: -11))
          default:
            continuation.resume(throwing: NSError(domain: "LocalAlbumStore", code: -12))
          }
        }
      }
    }
  }

  private func validateVideoFile(_ fileURL: URL) throws {
    let exists = FileManager.default.fileExists(atPath: fileURL.path)
    guard exists else {
      throw NSError(domain: "LocalAlbumStore", code: -20, userInfo: [
        NSLocalizedDescriptionKey: "待保存文件不存在",
      ])
    }
    let values = try fileURL.resourceValues(forKeys: [.isReadableKey, .fileSizeKey, .nameKey])
    if values.isReadable == false {
      throw NSError(domain: "LocalAlbumStore", code: -21, userInfo: [
        NSLocalizedDescriptionKey: "待保存文件不可读",
      ])
    }
    let size = values.fileSize ?? 0
    if size <= 0 {
      throw NSError(domain: "LocalAlbumStore", code: -22, userInfo: [
        NSLocalizedDescriptionKey: "待保存文件大小为0",
      ])
    }
    if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(fileURL.path) == false {
      throw NSError(domain: "LocalAlbumStore", code: -23, userInfo: [
        NSLocalizedDescriptionKey: "系统判定该视频不兼容相册",
      ])
    }
    Self.log("saveVideoFile validating ok name=\(values.name ?? fileURL.lastPathComponent) size=\(size) ext=\(fileURL.pathExtension)")
  }

  private func describeVideoSaveError(_ error: Error, fileURL: URL) -> String {
    let nsError = error as NSError
    let ext = fileURL.pathExtension.lowercased()
    let codeDesc = "domain=\(nsError.domain) code=\(nsError.code)"
    let detail = nsError.localizedDescription
    if nsError.domain == "PHPhotosErrorDomain" {
      return "系统相册写入失败(\(codeDesc)): \(detail)"
    }
    if nsError.domain == "LocalAlbumStore" {
      return "\(detail) (\(codeDesc))"
    }
    if ["mp4", "mov", "m4v"].contains(ext) == false {
      return "视频格式可能不受支持(\(ext))，\(detail)"
    }
    return "保存失败(\(codeDesc)): \(detail)"
  }

  private static func log(_ message: String) {
    #if DEBUG
      print("[LocalAlbumStore] \(message)")
    #endif
  }
}
