import SwiftUI
import WebKit

struct BasicWebView: View {
  let urlString: String
  let title: String?

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Text(title ?? "网页")
          .font(.system(size: 16, weight: .semibold))
        Spacer()
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 10)
      .background(Color.white)

      if let url = URL(string: urlString) {
        WebView(url: url)
      } else {
        VStack {
          Text("链接无效")
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .background(Color.white)
  }
}

private struct WebView: UIViewRepresentable {
  let url: URL

  func makeUIView(context _: Context) -> WKWebView {
    let webView = WKWebView()
    webView.scrollView.contentInsetAdjustmentBehavior = .never
    return webView
  }

  func updateUIView(_ webView: WKWebView, context _: Context) {
    if webView.url != url {
      webView.load(URLRequest(url: url))
    }
  }
}
