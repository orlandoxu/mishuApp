import Kingfisher
import SwiftUI
import UIKit

struct UserInfoEditView: View {
  @ObservedObject private var appNavigation = AppNavigationModel.shared
  @Environment(\.presentationMode) var presentationMode
  @StateObject private var selfStore: SelfStore = .shared

  @State private var showActionSheet = false
  @State private var showImagePicker = false
  @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
  @State private var isUploading = false

  var body: some View {
    VStack(spacing: 0) {
      NavHeader(title: "个人信息")

      ScrollView {
        VStack(spacing: 12) {
          // 头像区域
          VStack(spacing: 12) {
            UserAvatar(size: 80, avatar: selfStore.selfUser?.headImg)
              .overlay(
                Circle().stroke(Color(hex: "0xF5F5F5"), lineWidth: 1)
              )
              .onTapGesture {
                showActionSheet = true
              }

            Text("点击更换头像")
              .font(.system(size: 14))
              .foregroundColor(Color(hex: "0x999999"))
          }
          .padding(.top, 32)

          VStack {
            // 信息列表
            MeTextTitle(title: "基本信息")

            VStack(spacing: 0) {
              infoRow(title: "昵称", value: selfStore.selfUser?.nickname ?? "未设置") {
                appNavigation.push(.nicknameEdit)
              }

              Divider().padding(.leading, 16)

              infoRow(title: "手机号", value: maskMobile(selfStore.selfUser?.mobile ?? "")) {
                // 暂时不处理手机号变更
                ToastCenter.shared.show("手机号修改功能，将在下个版本支持")
              }

              Divider().padding(.leading, 16)

              infoRow(title: "密码", value: (selfStore.selfUser?.isSetPassword == true) ? "已设置" : "未设置") {
                appNavigation.push(.passwordEdit)
              }
            }
            .background(Color.white)
            .cornerRadius(12)
          }
          .padding(.horizontal, 16)
        }
      }
      .background(Color(hex: "0xF8F8F8").ignoresSafeArea())
    }
    .ignoresSafeArea()
    .background(Color.white.ignoresSafeArea())
    .navigationBarHidden(true)
    .actionSheet(isPresented: $showActionSheet) {
      ActionSheet(
        title: Text("更换头像"),
        buttons: [
          .default(Text("拍照")) {
            sourceType = .camera
            showImagePicker = true
          },
          .default(Text("从相册选择")) {
            sourceType = .photoLibrary
            showImagePicker = true
          },
          .cancel(Text("取消")),
        ]
      )
    }
    .sheet(isPresented: $showImagePicker) {
      ImagePicker(sourceType: sourceType) { image in
        uploadAvatar(image)
      }
      .ignoresSafeArea()
    }
    .overlay(
      Group {
        if isUploading {
          ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
            ProgressView("上传中...")
              .padding()
              .background(Color.white)
              .cornerRadius(8)
          }
        }
      }
    )
  }

  // private var avatarView: some View {
  //   Group {
  //     if let urlString = selfStore.selfUser?.headImg,
  //        let url = URL(string: urlString), !urlString.isEmpty
  //     {
  //       KFImage(url)
  //         .resizable()
  //         .scaledToFill()
  //     } else {
  //       // 使用默认头像 img_default_avatar
  //       Image("img_default_avatar")
  //         .resizable()
  //         .scaledToFit()
  //         .foregroundColor(Color(hex: "0xCCCCCC"))
  //         .background(Color(hex: "0xF5F5F5"))
  //     }
  //   }
  // }

  private func infoRow(title: String, value: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      HStack {
        Text(title)
          .font(.system(size: 16))
          .foregroundColor(Color(hex: "0x333333"))

        Spacer()

        Text(value)
          .font(.system(size: 16))
          .foregroundColor(Color(hex: "0x666666"))

        Image("icon_more_arrow")
          .resizable()
          .renderingMode(.template) // 允许修改颜色
          .foregroundColor(Color(hex: "0xCCCCCC"))
          .scaledToFit()
          .frame(width: 12, height: 12)
      }
      .padding(.horizontal, 16)
      .frame(height: 56)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  private func maskMobile(_ mobile: String) -> String {
    guard mobile.count >= 11 else { return mobile }
    let start = mobile.index(mobile.startIndex, offsetBy: 3)
    let end = mobile.index(mobile.endIndex, offsetBy: -4)
    return mobile.replacingCharacters(in: start ..< end, with: "****")
  }

  private func uploadAvatar(_ image: UIImage) {
    guard let data = image.jpegData(compressionQuality: 0.8) else { return }
    isUploading = true

    Task {
      // 1. 获取 token
      guard let uploadToken = await ResourceAPI.shared.getAvatarToken() else {
        await MainActor.run {
          ToastCenter.shared.show("获取上传凭证失败")
          isUploading = false
        }
        return
      }

      // 3. 上传图片
      guard let key = await UploadAPI.shared.uploadImage2QiNiu(
        data: data,
        mime: "image/jpeg",
        token: uploadToken
      ) else {
        await MainActor.run {
          ToastCenter.shared.show("头像上传失败")
          isUploading = false
        }
        return
      }

      // 4. 更新用户信息
      let url = uploadToken.baseUrl.removeTrailingSlash + "/" + key
      guard await UserAPI.shared.updateAvatar(url) != nil else {
        await MainActor.run {
          ToastCenter.shared.show("头像更新失败")
          isUploading = false
        }
        return
      }

      // 5. 刷新本地用户数据
      await selfStore.refresh()

      await MainActor.run {
        ToastCenter.shared.show("头像更新成功")
        isUploading = false
      }
    }
  }

  private var safeAreaTop: CGFloat {
    UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0
  }
}

/// 简单的 ImagePicker 封装
struct ImagePicker: UIViewControllerRepresentable {
  var sourceType: UIImagePickerController.SourceType
  var onImagePicked: (UIImage) -> Void

  func makeUIViewController(context: Context) -> UIImagePickerController {
    let picker = UIImagePickerController()
    picker.sourceType = sourceType
    picker.delegate = context.coordinator
    picker.allowsEditing = true
    return picker
  }

  func updateUIViewController(_: UIImagePickerController, context _: Context) {}

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    let parent: ImagePicker

    init(_ parent: ImagePicker) {
      self.parent = parent
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
      if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
        parent.onImagePicked(image)
      }
      picker.dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      picker.dismiss(animated: true)
    }
  }
}
