import AVFoundation
import SwiftUI
import UIKit
import Vision

enum BindMenuAction: Hashable {
  case qrcode
  case wifi
  case manual
}

struct VehicleHeaderView: View {
  let onlineCountText: String
  let onSelectAddMenu: (BindMenuAction) -> Void
  @StateObject private var permissionStore: CameraPermissionStore = .init()
  @State private var pendingAction: BindMenuAction?
  @State private var isPresentingPermissionAlert: Bool = false

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .center) {
        Text("记录仪")
          .font(.system(size: 28, weight: .bold))
          .foregroundColor(Color(hex: "0x111111"))

        Spacer()

        Menu {
          Button {
            handleQrCodeAction()
          } label: {
            HStack {
              Text("扫码绑定")
              Image("icon_bind_qrcode")
            }
          }

          Button {
            onSelectAddMenu(.wifi)
          } label: {
            HStack {
              Text("Wifi绑定")
              Image("icon_bind_wifi")
            }
          }

          Button {
            onSelectAddMenu(.manual)
          } label: {
            HStack {
              Text("手动绑定")
              Spacer()
              Image("icon_bind_hand")
            }
          }
        } label: {
          ZStack {
            Circle()
              .fill(Color.black.opacity(0.85))
              .frame(width: 40, height: 40)
            Image(systemName: "plus")
              .font(.system(size: 18, weight: .bold))
              .foregroundColor(.white)
          }
        }
        .buttonStyle(.plain)
      }

      Text(onlineCountText)
        .font(.system(size: 16, weight: .regular))
        .foregroundColor(Color(hex: "0x666666"))
    }
    .onChange(of: permissionStore.authorization) { status in
      handleAuthorizationChange(status)
    }
  }

  private func handleQrCodeAction() {
    pendingAction = .qrcode
    permissionStore.refresh()
    handleAuthorizationChange(permissionStore.authorization)
    permissionStore.requestIfNeeded()
  }

  private func handleAuthorizationChange(_ status: AVAuthorizationStatus) {
    if status == .authorized {
      if let action = pendingAction {
        pendingAction = nil
        onSelectAddMenu(action)
      }
      return
    }
    if status == .denied || status == .restricted {
      pendingAction = nil
      // ToastCenter.shared.show("没有相机权限")
      presentCameraPermissionAlert()
    }
  }

  private func presentCameraPermissionAlert() {
    // SwiftUI 中 Menu + 多层 alert 容易出现状态已变但不展示的问题，这里改为 UIKit 原生弹窗，确保稳定可见
    guard !isPresentingPermissionAlert else { return }
    isPresentingPermissionAlert = true
    presentPermissionAlertWhenReady(retry: 4)
  }

  private func openAppSettings() {
    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
    UIApplication.shared.open(url)
  }

  private func topViewController() -> UIViewController? {
    let scene = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive }
    let root = scene?.windows.first(where: { $0.isKeyWindow })?.rootViewController
    return topViewController(from: root)
  }

  private func topViewController(from root: UIViewController?) -> UIViewController? {
    if let nav = root as? UINavigationController {
      return topViewController(from: nav.visibleViewController)
    }
    if let tab = root as? UITabBarController {
      return topViewController(from: tab.selectedViewController)
    }
    if let presented = root?.presentedViewController {
      return topViewController(from: presented)
    }
    return root
  }

  private func presentPermissionAlertWhenReady(retry: Int) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
      guard let top = self.topViewController() else {
        self.isPresentingPermissionAlert = false
        return
      }

      if top.presentedViewController != nil {
        if retry > 0 {
          self.presentPermissionAlertWhenReady(retry: retry - 1)
        } else {
          self.isPresentingPermissionAlert = false
        }
        return
      }

      let alert = UIAlertController(
        title: "需要相机权限",
        message: "请在系统设置中开启相机权限后再使用扫码绑定。",
        preferredStyle: .alert
      )

      alert.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in
        self.isPresentingPermissionAlert = false
      })
      alert.addAction(UIAlertAction(title: "去设置", style: .default) { _ in
        self.isPresentingPermissionAlert = false
        self.openAppSettings()
      })
      top.present(alert, animated: true)
    }
  }
}
