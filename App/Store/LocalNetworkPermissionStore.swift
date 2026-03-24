import Foundation
import Network
import UIKit

// 目前本地网络有个大问题，还检测不准确！

enum LocalNetworkAuthorizationStatus {
  case unknown
  case granted
  case denied
}

final class LocalNetworkPermissionStore: ObservableObject {
  static let shared = LocalNetworkPermissionStore()

  @Published private(set) var status: LocalNetworkAuthorizationStatus = .unknown
  private var browser: NWBrowser?
  private var isProbing = false
  private var observers: [NSObjectProtocol] = []

  private init() {
    let center = NotificationCenter.default
    let didBecomeActive = center.addObserver(
      forName: UIApplication.didBecomeActiveNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.refresh()
    }
    observers = [didBecomeActive]
  }

  var isDenied: Bool {
    status == .denied
  }

  func refresh() {
    requestIfNeeded()
  }

  func requestIfNeeded() {
    startProbe()
  }

  func openAppSettings() {
    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
    UIApplication.shared.open(url)
  }

  private func startProbe() {
    if isProbing { return }
    isProbing = true
    browser?.cancel()
    let params = NWParameters()
    params.includePeerToPeer = true
    let probe = NWBrowser(for: .bonjour(type: "_http._tcp", domain: nil), using: params)
    browser = probe
    probe.browseResultsChangedHandler = { _, _ in }
    probe.stateUpdateHandler = { [weak self] state in
      guard let self else { return }
      switch state {
      case .ready:
        // print("LocalNetworkPermissionStore: ready")
        self.status = .granted
        self.finishProbe()
      case let .failed(error):
        // print("LocalNetworkPermissionStore: failed with error: \(error)")
        if self.isPermissionDenied(error) {
          // print("LocalNetworkPermissionStore: permission denied")
          self.status = .denied
        }
        self.finishProbe()
      case .cancelled:
        // print("LocalNetworkPermissionStore: cancelled")
        self.finishProbe()
      default:
        break
      }
    }
    probe.start(queue: .main)
    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
      self?.finishProbe()
    }
  }

  private func finishProbe() {
    browser?.cancel()
    browser = nil
    isProbing = false
  }

  private func isPermissionDenied(_ error: NWError) -> Bool {
    switch error {
    case let .posix(code):
      print("LocalNetworkPermissionStore: isPermissionDenied with posix code: \(code)")
      return code == .EPERM || code == .EACCES

    case let .dns(dnsError):
      print("LocalNetworkPermissionStore: isPermissionDenied with dns error: \(dnsError)")
      // 打印kDNSServiceErr_PolicyDenied
      print("LocalNetworkPermissionStore: isPermissionDenied with dns error: \(kDNSServiceErr_PolicyDenied)")
      return dnsError == kDNSServiceErr_PolicyDenied || dnsError == kDNSServiceErr_NoAuth

    default:
      print("LocalNetworkPermissionStore: isPermissionDenied with default error: \(error)")
      let nsError = error as NSError
      return nsError.code == -65555 // ⭐ NoAuth
    }
  }
}
