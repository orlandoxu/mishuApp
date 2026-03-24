import SwiftUI
import UIKit

struct BlurViewIos13: UIViewRepresentable {
  let style: UIBlurEffect.Style

  func makeUIView(context _: Context) -> UIVisualEffectView {
    UIVisualEffectView(effect: UIBlurEffect(style: style))
  }

  func updateUIView(_: UIVisualEffectView, context _: Context) {}
}

struct BlurView: View {
  var body: some View {
    if #available(iOS 15.0, *) {
      Rectangle().fill(.ultraThickMaterial)
    } else {
      BlurViewIos13(style: .systemThickMaterial)
    }
  }
}
