struct RouteParam: Hashable {
  let key: String
  let value: String
}

enum RoutePresentation: String, Hashable, CaseIterable {
  case push
  case sheet
  case fullScreen
}

enum AppRoute: Hashable {
  case page(path: String, params: [RouteParam], presentation: RoutePresentation)
}
