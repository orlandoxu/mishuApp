import SwiftUI

extension View {
  func matchedGeometryEffectIfLet(id: String, in ns: Namespace.ID?) -> some View {
    if let ns = ns {
      return AnyView(matchedGeometryEffect(id: id, in: ns))
    } else {
      return AnyView(self)
    }
  }
}
