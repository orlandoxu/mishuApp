import Foundation

enum RouteParser {
  static func parseLinkProtocol(_ url: URL) -> AppRoute? {
    let scheme = (url.scheme ?? "").lowercased()
    guard scheme == "https" || scheme == "http" else { return nil }

    let path = url.path
    if path == "/message" || path == "/app/message" {
      return .page(path: "/message", params: [], presentation: .push)
    }

    if path == "/webview" {
      guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
      let items = components.queryItems ?? []
      let urlValue = items.first(where: { $0.name == "url" })?.value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      guard !urlValue.isEmpty else { return nil }
      let title = items.first(where: { $0.name == "title" })?.value
      let navValue = (items.first(where: { $0.name == "nav" })?.value ?? "").lowercased()
      let showNav = navValue != "false" && navValue != "0"
      var params: [RouteParam] = [RouteParam(key: "url", value: urlValue)]
      if let title, !title.isEmpty {
        params.append(RouteParam(key: "title", value: title))
      }
      params.append(RouteParam(key: "hideNav", value: showNav ? "false" : "true"))
      return .page(path: "/webview", params: params, presentation: .push)
    }

    if path.hasSuffix("/services/pages/travel.html") {
      return .page(
        path: "/webview",
        params: [RouteParam(key: "url", value: url.absoluteString)],
        presentation: .push
      )
    }

    return nil
  }

  static func parse(_ raw: String) -> AppRoute {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty {
      return .page(path: "/home/index", params: [], presentation: .push)
    }

    let (presentation, normalized) = normalizePresentation(from: trimmed)

    if let components = URLComponents(string: normalized) {
      if let url = components.url, url.scheme != nil {
        let path = components.path.isEmpty ? "/" : components.path
        let params = (components.queryItems ?? []).map { RouteParam(key: $0.name, value: $0.value ?? "") }
        return .page(path: path, params: params, presentation: presentation)
      }
    }

    let parts = normalized.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)
    let path = parts.first.map(String.init) ?? "/"
    let query = parts.count > 1 ? String(parts[1]) : ""
    let params = parseQuery(query)
    return .page(path: path.isEmpty ? "/" : path, params: params, presentation: presentation)
  }

  private static func normalizePresentation(from raw: String) -> (RoutePresentation, String) {
    if raw.hasPrefix("sheet:") {
      return (.sheet, String(raw.dropFirst("sheet:".count)))
    }
    if raw.hasPrefix("fullscreen:") {
      return (.fullScreen, String(raw.dropFirst("fullscreen:".count)))
    }
    if raw.hasPrefix("full:") {
      return (.fullScreen, String(raw.dropFirst("full:".count)))
    }
    if raw.hasPrefix("push:") {
      return (.push, String(raw.dropFirst("push:".count)))
    }
    return (.push, raw)
  }

  private static func parseQuery(_ query: String) -> [RouteParam] {
    if query.isEmpty { return [] }
    return query
      .split(separator: "&")
      .map(String.init)
      .compactMap { pair -> RouteParam? in
        let parts = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
        let key = parts.first.map(String.init) ?? ""
        if key.isEmpty { return nil }
        let value = parts.count > 1 ? String(parts[1]) : ""
        return RouteParam(key: key, value: value)
      }
  }
}
