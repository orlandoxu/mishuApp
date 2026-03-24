import Photos
import SwiftUI

struct WeChatServiceView: View {
  @ObservedObject private var appNavigation = AppNavigationModel.shared
  @State private var isSaving = false

  var body: some View {
    VStack(spacing: 0) {
      NavHeader(title: "添加客服")

      VStack(spacing: 0) {
        Spacer().frame(height: 60)

        Text("请使用微信扫码")
          .font(.system(size: 24, weight: .medium))
          .foregroundColor(Color(hex: "0x111111"))

        Spacer()
          .frame(height: 40)

        Image("img_service_qrcode")
          .resizable()
          .scaledToFit()
          .frame(width: 240, height: 240)

        Spacer().frame(height: 60)

        Button {
          saveQRCode()
        } label: {
          HStack(spacing: 8) {
            Image("icon_settings_update")
              .font(.system(size: 16))
            Text("保存二维码到相册")
              .font(.system(size: 16, weight: .regular))
          }
          .foregroundColor(Color(hex: "0x333333"))
          .frame(width: 240, height: 44)
          .background(Color.white)
          .cornerRadius(6)
          .overlay(
            RoundedRectangle(cornerRadius: 6)
              .stroke(ThemeColor.gray100, lineWidth: 1)
          )
        }
        .disabled(isSaving)

        Spacer()
      }
      .frame(maxWidth: .infinity)
      .background(Color(hex: "0xF8F8F8").ignoresSafeArea())
    }
    .ignoresSafeArea()
    .navigationBarHidden(true)
    .background(Color.white)
  }

  private func saveQRCode() {
    isSaving = true

    // Check permission
    let status = PHPhotoLibrary.authorizationStatus()
    switch status {
    case .notDetermined:
      PHPhotoLibrary.requestAuthorization { newStatus in
        DispatchQueue.main.async {
          if newStatus == .authorized || newStatus == .limited {
            self.performSave()
          } else {
            self.showPermissionAlert()
            self.isSaving = false
          }
        }
      }
    case .restricted, .denied:
      showPermissionAlert()
      isSaving = false
    case .authorized, .limited:
      performSave()
    @unknown default:
      isSaving = false
    }
  }

  private func performSave() {
    guard let image = UIImage(named: "img_service_qrcode") else {
      ToastCenter.shared.show("找不到二维码图片")
      isSaving = false
      return
    }

    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    // Since UIImageWriteToSavedPhotosAlbum is async but doesn't provide a block easily in SwiftUI without a selector,
    // and we are in a struct, we can use PHPhotoLibrary for better control or just assume success/failure or use a coordinator.
    // Simpler approach for now:

    // Using PHPhotoLibrary to ensure we know when it's done
    PHPhotoLibrary.shared().performChanges {
      PHAssetChangeRequest.creationRequestForAsset(from: image)
    } completionHandler: { success, error in
      DispatchQueue.main.async {
        self.isSaving = false
        if success {
          ToastCenter.shared.show("保存成功")
        } else {
          ToastCenter.shared.show("保存失败：\(error?.localizedDescription ?? "未知错误")")
        }
      }
    }
  }

  private func showPermissionAlert() {
    // In a real app, show an alert with a button to open settings
    ToastCenter.shared.show("请在设置中允许访问相册")
  }

  private var safeAreaTop: CGFloat {
    UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0
  }
}
