import SwiftUI
import WebKit

struct WebContainerView: View {
  let urlString: String
  let title: String?
  var showNavigationBar: Bool = true
  var notice: String? = nil
  @State private var isLoading: Bool = true
  @State private var loadErrorText: String? = nil

  var body: some View {
    VStack(spacing: 0) {
      if showNavigationBar {
        // Spacer().frame(height: safeAreaTop).background(Color.white)
        NavHeader(title: title ?? "Web")
      }

      if let notice = notice {
        HStack(spacing: 12) {
          Text(notice)
            .font(.system(size: 16))
            .foregroundColor(Color(hex: "0x333333"))
          Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(hex: "0xFFF3D9"))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
      }

      ZStack {
        if let url = buildURL(from: urlString) {
          if let loadErrorText {
            VStack(spacing: 10) {
              Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)
              Text("页面加载失败")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "0x333333"))
              Text(loadErrorText)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "0x999999"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
          } else {
            WebView(url: url, isLoading: $isLoading, loadErrorText: $loadErrorText)

            if isLoading {
              ProgressView()
            }
          }
        } else {
          Text("Invalid URL: \(urlString)")
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
      }
    }
    .ignoresSafeArea()
    .navigationBarHidden(true)
  }

  private var safeAreaTop: CGFloat {
    UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0
  }

  private func buildURL(from string: String) -> URL? {
    if let url = URL(string: string), url.scheme != nil {
      return url
    }
    // Try decoding if it was percent encoded
    if let decoded = string.removingPercentEncoding, let url = URL(string: decoded), url.scheme != nil {
      return url
    }
    return nil
  }
}

private struct WebView: UIViewRepresentable {
  let url: URL
  @Binding var isLoading: Bool
  @Binding var loadErrorText: String?

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  func makeUIView(context: Context) -> WKWebView {
    let config = WKWebViewConfiguration()
    // config.websiteDataStore = .nonPersistent() // Optional
    let webView = WKWebView(frame: .zero, configuration: config)
    webView.navigationDelegate = context.coordinator
    webView.uiDelegate = context.coordinator
    webView.allowsBackForwardNavigationGestures = true
    return webView
  }

  func updateUIView(_ webView: WKWebView, context _: Context) {
    // 仅在首次没有任何页面时加载初始 URL，避免覆盖 H5 内部跳转导致 -999 取消错误
    if webView.url == nil {
      let request = URLRequest(url: url)
      webView.load(request)
    }
  }

  class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
    var parent: WebView
    private var provisionalStartTimestamps: [TimeInterval] = []
    private var hasFatalLoadError = false

    init(_ parent: WebView) {
      self.parent = parent
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
      if hasFatalLoadError {
        webView.stopLoading()
        return
      }

      let now = Date().timeIntervalSince1970
      provisionalStartTimestamps.append(now)
      provisionalStartTimestamps.removeAll { now - $0 > 5 }
      if provisionalStartTimestamps.count > 10 {
        markFatalError(webView: webView, message: "页面跳转异常，请稍后重试")
        return
      }
      parent.isLoading = true
    }

    func webView(_: WKWebView, didFinish _: WKNavigation!) {
      provisionalStartTimestamps.removeAll()
      parent.isLoading = false
    }

    func webView(_ webView: WKWebView, didFail _: WKNavigation!, withError error: Error) {
      if isCancelledError(error) { return }
      markFatalError(webView: webView, message: error.localizedDescription)
      print("WebView error: \(error.localizedDescription)")
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError error: Error) {
      if isCancelledError(error) { return }
      markFatalError(webView: webView, message: error.localizedDescription)
      print("WebView provisional error: \(error.localizedDescription)")
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
      if hasFatalLoadError {
        decisionHandler(.cancel)
        return
      }

      guard let url = navigationAction.request.url else {
        decisionHandler(.allow)
        return
      }

      if navigationAction.targetFrame == nil {
        webView.load(navigationAction.request)
        decisionHandler(.cancel)
        return
      }

      let scheme = (url.scheme ?? "").lowercased()
      if scheme == "http" || scheme == "https" {
        decisionHandler(.allow)
      } else {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        decisionHandler(.cancel)
      }
    }

    func webView(_ webView: WKWebView, createWebViewWith _: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures _: WKWindowFeatures) -> WKWebView? {
      if hasFatalLoadError {
        return nil
      }
      if navigationAction.targetFrame == nil {
        webView.load(navigationAction.request)
      }
      return nil
    }

    private func markFatalError(webView: WKWebView, message: String) {
      hasFatalLoadError = true
      parent.isLoading = false
      parent.loadErrorText = message
      webView.stopLoading()
    }

    private func isCancelledError(_ error: Error) -> Bool {
      (error as NSError).code == NSURLErrorCancelled
    }
  }
}
