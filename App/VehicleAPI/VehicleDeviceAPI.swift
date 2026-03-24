import Foundation
import Network

final class VehicleDeviceAPI {
  static let shared = VehicleDeviceAPI()

  private init() {}

  func fetchDeviceInfo() async -> VehicleDeviceInfo? {
    guard let url = URL(string: "http://192.168.42.129/cgi-bin/cgi-version") else { return nil }
    let response = await DeviceCommCenter.shared.request(.get(url), timeout: 3)
    guard response.statusCode == 200 else { return nil }
    guard let body = response.body else { return nil }
    guard let parsed = parseVersionResponse(body) else { return nil }
    return VehicleDeviceInfo(imei: parsed.imei, sn: parsed.sn, chipId: nil, obdSn: nil, isObdDevice: nil)
  }

  private func parseVersionResponse(_ response: String) -> (imei: String, sn: String)? {
    guard let data = response.data(using: .utf8) else { return nil }
    let parserDelegate = DeviceVersionXMLParser()
    let parser = XMLParser(data: data)
    parser.delegate = parserDelegate
    let success = parser.parse()
    if !success { return nil }
    guard let imei = parserDelegate.imei, let sn = parserDelegate.sn else { return nil }
    if imei.isEmpty || sn.isEmpty { return nil }
    return (imei: imei, sn: sn)
  }
}

struct VehicleDeviceInfo: Decodable {
  let imei: String?
  let sn: String?
  let chipId: String?
  let obdSn: String?
  let isObdDevice: Bool?
}

final class DeviceCommCenter {
  static let shared = DeviceCommCenter()
  private let session: URLSession
  private var permissionBrowser: NWBrowser?

  private init() {
    let config = URLSessionConfiguration.ephemeral
    config.timeoutIntervalForRequest = 5
    config.timeoutIntervalForResource = 5
    session = URLSession(configuration: config)
  }

  func request(_ request: DeviceCommRequest, timeout: TimeInterval) async -> DeviceCommResponse {
    prepareLocalNetworkAccess()
    var urlRequest = URLRequest(url: request.url)
    urlRequest.httpMethod = request.method.rawValue
    urlRequest.timeoutInterval = timeout
    logRequest(request: request, timeout: timeout)
    do {
      let (data, response) = try await session.data(for: urlRequest)
      let status = (response as? HTTPURLResponse)?.statusCode ?? -1
      let body = String(data: data, encoding: .utf8) ?? ""
      let result = DeviceCommResponse(statusCode: status, body: body)
      logResponse(request: request, response: result)
      return result
    } catch {
      let result = DeviceCommResponse(statusCode: -1, body: nil)
      logError(request: request, error: error)
      return result
    }
  }

  func requestLocalNetworkPermission() {
    prepareLocalNetworkAccess()
  }

  private func prepareLocalNetworkAccess() {
    if permissionBrowser != nil { return }
    let params = NWParameters()
    params.includePeerToPeer = true
    let browser = NWBrowser(for: .bonjour(type: "_http._tcp", domain: nil), using: params)
    permissionBrowser = browser
    browser.browseResultsChangedHandler = { _, _ in }
    browser.stateUpdateHandler = { [weak self] state in
      if case .failed = state {
        self?.permissionBrowser?.cancel()
        self?.permissionBrowser = nil
      }
    }
    browser.start(queue: .main)
    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
      self?.permissionBrowser?.cancel()
      self?.permissionBrowser = nil
    }
  }

  private func logRequest(request: DeviceCommRequest, timeout: TimeInterval) {
    LKLog(
      "device request method=\(request.method.rawValue) url=\(request.url.absoluteString) timeout=\(timeout)",
      type: "device",
      label: "info"
    )
  }

  private func logResponse(request: DeviceCommRequest, response: DeviceCommResponse) {
    LKLog(
      "device response url=\(request.url.absoluteString) status=\(response.statusCode) body=\(truncated(response.body ?? "-", limit: 400))",
      type: "device",
      label: "info"
    )
  }

  private func logError(request: DeviceCommRequest, error: Error) {
    let message = error.localizedDescription
    if message.contains("Local network prohibited") {
      LKLog("local network denied url=\(request.url.absoluteString)", type: "device", label: "warning")
    }
    LKLog("device request error url=\(request.url.absoluteString) error=\(message)", type: "device", label: "error")
  }

  private func truncated(_ text: String, limit: Int) -> String {
    if text.count <= limit { return text }
    let index = text.index(text.startIndex, offsetBy: limit)
    return String(text[..<index]) + "...<truncated>"
  }
}

struct DeviceCommRequest {
  enum Method: String {
    case get = "GET"
  }

  let method: Method
  let url: URL

  static func get(_ url: URL) -> DeviceCommRequest {
    DeviceCommRequest(method: .get, url: url)
  }
}

struct DeviceCommResponse {
  let statusCode: Int
  let body: String?
}

private final class DeviceVersionXMLParser: NSObject, XMLParserDelegate {
  private(set) var imei: String?
  private(set) var sn: String?
  private var currentElement: String?
  private var buffer: String = ""

  func parser(_: XMLParser, didStartElement elementName: String, namespaceURI _: String?, qualifiedName _: String?, attributes _: [String: String] = [:]) {
    currentElement = elementName.lowercased()
    buffer = ""
  }

  func parser(_: XMLParser, foundCharacters string: String) {
    buffer += string
  }

  func parser(_: XMLParser, didEndElement elementName: String, namespaceURI _: String?, qualifiedName _: String?) {
    let value = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
    if !value.isEmpty {
      let name = elementName.lowercased()
      if name == "imei" {
        imei = value
      } else if name == "sn" {
        sn = value
      }
    }
    currentElement = nil
    buffer = ""
  }
}
