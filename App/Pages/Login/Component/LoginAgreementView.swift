import SwiftUI
import UIKit

struct LoginAgreementView: View {
  @Binding var agreed: Bool

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

  private var agreementAttributedText: NSAttributedString {
    let text = "已读并同意《使用协议》《隐私政策》"
    let attributedString = NSMutableAttributedString(string: text)

    let range = NSRange(location: 0, length: text.count)
    attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 16), range: range)
    attributedString.addAttribute(.foregroundColor, value: ThemeColor.gray600Ui, range: range)

    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineSpacing = 4
    attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)

    let nsText = text as NSString
    let termRange = nsText.range(of: "《使用协议》")
    let privacyRange = nsText.range(of: "《隐私政策》")

    let activeBlue = ThemeColor.brand500Ui

    if termRange.location != NSNotFound {
      attributedString.addAttribute(.link, value: "mishu://agreement", range: termRange)
      attributedString.addAttribute(.foregroundColor, value: activeBlue, range: termRange)
    }

    if privacyRange.location != NSNotFound {
      attributedString.addAttribute(.link, value: "mishu://privacy", range: privacyRange)
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
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)

      HyperlinkText(text: agreementAttributedText, onLinkTap: { url in
        if url.host == "agreement" {
          openExternalLink(getUseAgreementUrl())
        } else if url.host == "privacy" {
          openExternalLink(getPrivacyPolicyUrl())
        }
      }, onToggle: {
        agreed.toggle()
      })
      .fixedSize(horizontal: false, vertical: true)
    }
    .padding(.horizontal, 30)
    .padding(.bottom, 20)
  }

  private func openExternalLink(_ raw: String) {
    guard let url = URL(string: raw) else { return }
    UIApplication.shared.open(url)
  }
}

private struct HyperlinkText: UIViewRepresentable {
  let text: NSAttributedString
  let onLinkTap: (URL) -> Void
  let onToggle: () -> Void

  func makeUIView(context: Context) -> UITextView {
    let textView = UITextView()
    textView.isEditable = false
    textView.isSelectable = false
    textView.isScrollEnabled = false
    textView.backgroundColor = .clear
    textView.textContainerInset = .zero
    textView.textContainer.lineFragmentPadding = 0

    let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
    textView.addGestureRecognizer(tapGesture)
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
      let location = gesture.location(in: textView)
      var locationInTextContainer = CGPoint(x: location.x, y: location.y)
      locationInTextContainer.x -= textView.textContainerInset.left
      locationInTextContainer.y -= textView.textContainerInset.top

      let charIndex = textView.layoutManager.characterIndex(for: locationInTextContainer, in: textView.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)

      if charIndex < textView.textStorage.length,
         let link = textView.textStorage.attribute(.link, at: charIndex, effectiveRange: nil)
      {
        if let urlStr = link as? String, let url = URL(string: urlStr) {
          parent.onLinkTap(url)
          return
        }
        if let url = link as? URL {
          parent.onLinkTap(url)
          return
        }
      }

      parent.onToggle()
    }
  }
}
