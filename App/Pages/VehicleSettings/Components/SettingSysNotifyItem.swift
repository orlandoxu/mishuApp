import SwiftUI
import UIKit

struct SettingSysNotifyItem: View {
  let item: TemplateItem
  @ObservedObject private var noticeStore = NoticePermissionStore.shared

  var body: some View {
    Group {
      if shouldShowNotifyPrompt {
        HStack(spacing: 12) {
          VStack(alignment: .leading, spacing: 6) {
            Text("请先打开系统通知")
              .font(.system(size: 16, weight: .medium))
              .foregroundColor(Color(hex: "0x333333"))
          }

          Spacer(minLength: 8)

          Button {
            noticeStore.openAppSettings()
          } label: {
            Text("去设置")
              .font(.system(size: 12, weight: .medium))
              .foregroundColor(.white)
              .padding(.horizontal, 12)
              .padding(.vertical, 6)
              .background(Color(hex: "0x28C4FB"))
              .cornerRadius(12)
          }
          .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(hex: "0xFFF3D9"))
        .cornerRadius(12)
      }
    }
    .onAppear {
      noticeStore.refresh()
    }
    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
      noticeStore.refresh()
    }
  }

  private var shouldShowNotifyPrompt: Bool {
    switch noticeStore.authorizationStatus {
    case .authorized, .provisional, .ephemeral:
      return false
    default:
      return true
    }
  }
}
