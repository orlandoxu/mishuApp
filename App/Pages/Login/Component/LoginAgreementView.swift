import SwiftUI
import UIKit

struct LoginAgreementView: View {
  @Binding var agreed: Bool
  @ObservedObject private var appNavigation = AppNavigationModel.shared

  private var isHans: Bool {
    let preferred = Locale.preferredLanguages.first ?? ""
    return preferred.contains("Hans") || preferred.contains("zh-Hans") || preferred.contains("zh-CN")
  }

  private func getUseAgreementUrl() -> String {
    isHans
      ? "https://wx-server.spreadwin.com/services/frontpage/html/TuYunUserTerm.html"
      : "https://wx-server.spreadwin.com/services/frontpage/html/TuYunUserTerm_HK.html"
  }

  private func getPrivacyPolicyUrl() -> String {
    isHans
      ? "https://wx-server.spreadwin.com/services/frontpage/html/TuYunPrivateTerm.html"
      : "https://wx-server.spreadwin.com/services/frontpage/html/TuYunPrivateTerm_HK.html"
  }

  // DONE-AI: 使用协议，隐私政策，文字颜色使用品牌色
  private var agreementAttributedText: NSAttributedString {
    let text = "已读并同意《使用协议》《隐私政策》"
    let attributedString = NSMutableAttributedString(string: text)

    // Base attributes
    let range = NSRange(location: 0, length: text.count)
    attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 16), range: range)
    attributedString.addAttribute(.foregroundColor, value: ThemeColor.gray600Ui, range: range)

    // Paragraph style for line spacing
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineSpacing = 4
    attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)

    // Links
    let nsText = text as NSString
    let termRange = nsText.range(of: "《使用协议》")
    let privacyRange = nsText.range(of: "《隐私政策》")

    let activeBlue = ThemeColor.brand500Ui

    if termRange.location != NSNotFound {
      attributedString.addAttribute(.link, value: "tuyun://agreement", range: termRange)
      attributedString.addAttribute(.foregroundColor, value: activeBlue, range: termRange)
    }

    if privacyRange.location != NSNotFound {
      attributedString.addAttribute(.link, value: "tuyun://privacy", range: privacyRange)
      attributedString.addAttribute(.foregroundColor, value: activeBlue, range: privacyRange)
    }

    return attributedString
  }

  var body: some View {
    HStack(alignment: .center, spacing: 8) {
      Button {
        agreed.toggle()
      } label: {
        Image(systemName: agreed ? "checkmark.square.fill" : "square")
          .foregroundColor(
            agreed
              ? ThemeColor.brand500
              : Color.gray.opacity(0.5)
          )
          .font(.system(size: 24))
          // 整个都可以点击
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)

      HyperlinkText(text: agreementAttributedText, onLinkTap: { url in
        if url.scheme == "tuyun" {
          if url.host == "agreement" {
            appNavigation.push(.web(url: getUseAgreementUrl(), title: "使用协议", hideNav: false))
          } else if url.host == "privacy" {
            appNavigation.push(.web(url: getPrivacyPolicyUrl(), title: "隐私政策", hideNav: false))
          }
        }
      }, onToggle: {
        agreed.toggle()
      })
      .fixedSize(horizontal: false, vertical: true)
    }
    .padding(.horizontal, 30)
    .padding(.bottom, 20)
  }
}

private struct HyperlinkText: UIViewRepresentable {
  let text: NSAttributedString
  let onLinkTap: (URL) -> Void
  let onToggle: () -> Void

  func makeUIView(context: Context) -> UITextView {
    let textView = UITextView()
    // Disable selection and editing to prevent menu/magnifier
    textView.isEditable = false
    textView.isSelectable = false
    textView.isScrollEnabled = false
    textView.backgroundColor = .clear
    textView.textContainerInset = .zero
    textView.textContainer.lineFragmentPadding = 0

    // Add tap gesture for custom handling
    let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
    textView.addGestureRecognizer(tapGesture)

    // Remove link underlining if desired, or keep default
    // Note: Since isSelectable=false, these attributes might not apply automatically for "link" look if we rely on system behavior,
    // but we are passing attributed string which has .foregroundColor set.
    return textView
  }

  func updateUIView(_ uiView: UITextView, context _: Context) {
    uiView.attributedText = text
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject {
    var parent: HyperlinkText

    init(_ parent: HyperlinkText) {
      self.parent = parent
    }

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
      guard let textView = gesture.view as? UITextView else { return }

      // Get location of tap
      let location = gesture.location(in: textView)
      let position = CGPoint(x: location.x, y: location.y)

      // Get character index at tap location
      // This requires layout manager logic
      let layoutManager = textView.layoutManager
      var locationInTextContainer = position
      locationInTextContainer.x -= textView.textContainerInset.left
      locationInTextContainer.y -= textView.textContainerInset.top

      let charIndex = layoutManager.characterIndex(for: locationInTextContainer, in: textView.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)

      if charIndex < textView.textStorage.length {
        // Check for link attribute
        if let link = textView.textStorage.attribute(.link, at: charIndex, effectiveRange: nil) {
          if let urlStr = link as? String, let url = URL(string: urlStr) {
            parent.onLinkTap(url)
            return
          } else if let url = link as? URL {
            parent.onLinkTap(url)
            return
          }
        }
      }

      // If not link, treat as toggle
      parent.onToggle()
    }
  }
}
