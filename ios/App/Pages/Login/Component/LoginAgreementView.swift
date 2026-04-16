import SwiftUI
import UIKit

struct LoginAgreementView: View {
  @Binding var agreed: Bool
  var shake: Bool = false

  private var isHans: Bool {
    let preferred = Locale.preferredLanguages.first ?? ""
    return preferred.contains("Hans") || preferred.contains("zh-Hans") || preferred.contains("zh-CN")
  }

  private var agreementURL: String {
    isHans
      ? "https://wx-server.spreadwin.com/services/frontpage/html/TuYunUserTerm.html"
      : "https://wx-server.spreadwin.com/services/frontpage/html/TuYunUserTerm_HK.html"
  }

  private var privacyURL: String {
    isHans
      ? "https://wx-server.spreadwin.com/services/frontpage/html/TuYunPrivateTerm.html"
      : "https://wx-server.spreadwin.com/services/frontpage/html/TuYunPrivateTerm_HK.html"
  }

  var body: some View {
    HStack(alignment: .center, spacing: 10) {
      Button {
        agreed.toggle()
      } label: {
        ZStack {
          Circle()
            .stroke(Color(hex: "C7CBD3"), lineWidth: 1.5)
            .frame(width: 24, height: 24)
          if agreed {
            Image(systemName: "checkmark")
              .font(.system(size: 10, weight: .bold))
              .foregroundColor(Color(hex: "2F3740"))
          }
        }
      }
      .buttonStyle(.plain)

      agreementText
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .contentShape(Rectangle())
    .onTapGesture {
      agreed.toggle()
    }
    .padding(.horizontal, 28)
    .padding(.bottom, 12)
    .offset(x: shake ? -4 : 0)
    .animation(
      shake ? .easeInOut(duration: 0.08).repeatCount(4, autoreverses: true) : .default,
      value: shake
    )
  }

  private var agreementText: some View {
    HStack(spacing: 0) {
      Text("我已阅读并同意 ")
        .foregroundColor(Color(hex: "989DA8"))
      Button("《用户协议》") {
        if !agreed { agreed = true }
        openExternalLink(agreementURL)
      }
      .foregroundColor(Color(hex: "1F8BFF"))
      .buttonStyle(.plain)
      Text(" 和 ")
        .foregroundColor(Color(hex: "989DA8"))
      Button("《隐私政策》") {
        if !agreed { agreed = true }
        openExternalLink(privacyURL)
      }
      .foregroundColor(Color(hex: "1F8BFF"))
      .buttonStyle(.plain)
    }
    .font(.system(size: 15, weight: .regular))
  }

  private func openExternalLink(_ raw: String) {
    guard let url = URL(string: raw) else { return }
    UIApplication.shared.open(url)
  }
}
