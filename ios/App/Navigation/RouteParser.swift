import Foundation

enum RouteParser {
  static func parseLinkProtocol(_ url: URL) -> AppRoute? {
    let scheme = (url.scheme ?? "").lowercased()
    guard scheme == "https" || scheme == "http" else { return nil }

    let path = url.path
    guard path == "/webview" else { return nil }

    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
    let items = components.queryItems ?? []
    let urlValue = items.first(where: { $0.name == "url" })?.value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    guard !urlValue.isEmpty else { return nil }

    let title = items.first(where: { $0.name == "title" })?.value
    var params: [RouteParam] = [RouteParam(key: "url", value: urlValue)]
    if let title, !title.isEmpty {
      params.append(RouteParam(key: "title", value: title))
    }

    return .page(path: "/webview", params: params, presentation: .push)
  }

  static func parse(_ raw: String) -> AppRoute {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty {
      return .page(path: "/", params: [], presentation: .push)
    }

    let parts = trimmed.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)
    let path = parts.first.map(String.init) ?? "/"
    let query = parts.count > 1 ? String(parts[1]) : ""
    let params = parseQuery(query)
    return .page(path: path.isEmpty ? "/" : path, params: params, presentation: .push)
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
