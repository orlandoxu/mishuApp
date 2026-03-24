import AVFoundation
import Kingfisher
import SwiftUI
import UIKit

// DONE-AI: vin输完了之后，键盘需要自动收起来

struct CarInfoStep2View: View {
  @ObservedObject private var appNavigation = AppNavigationModel.shared
  @Environment(\.scenePhase) private var scenePhase
  @StateObject private var bindingStore: BindingStore = .shared
  @StateObject private var cameraPermissionStore: CameraPermissionStore = .init()

  @State private var isPresentingCamera: Bool = false
  @State private var isPresentingPhotoPicker: Bool = false
  @State private var isPresentingVinSourceSheet: Bool = false
  @State private var isRecognizing: Bool = false
  @State private var shouldPresentCameraAfterAuthorization: Bool = false
  @State private var isPresentingCameraSettingsAlert: Bool = false
  @State private var isVinKeyboardVisible: Bool = false
  @State private var vinCursorIndex: Int = 0

  var body: some View {
    ZStack {
      Color.white.ignoresSafeArea()

      VStack(spacing: 0) {
        // Navigation Bar
        HStack(spacing: 0) {
          Button {
            appNavigation.pop()
          } label: {
            ZStack {
              Circle()
                .fill(Color.black.opacity(0.001))
                .frame(width: 44, height: 44)
              Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color(hex: "0x111111"))
            }
          }
          .buttonStyle(.plain)

          Text("车辆信息")
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(Color(hex: "0x111111"))
            .padding(.leading, 4)

          Spacer()

          Text("\(bindingStore.currentStep)/\(bindingStore.totalStepCount)")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(Color(hex: "0x999999"))
        }
        .padding(.horizontal, 16)
        .frame(height: 56 + safeAreaTop)

        ScrollView {
          VStack(alignment: .leading, spacing: 24) {
            Text("请输入或扫描车辆VIN码（车架号）。")
              .font(.system(size: 16, weight: .regular))
              .foregroundColor(Color(hex: "0x333333"))

            // Scan Button Area
            Button {
              presentVinSourceSheet()
            } label: {
              VStack(spacing: 12) {
                if let imgUrl = bindingStore.vinImg as String?, !imgUrl.isEmpty, let url = URL(string: imgUrl) {
                  // 回显图片
                  KFImage(url)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 140)
                    .clipped()
                    .cornerRadius(12)
                } else {
                  ZStack {
                    Circle()
                      .fill(Color.white)
                      .frame(width: 48, height: 48)
                      .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)

                    if isRecognizing {
                      ProgressView()
                    } else {
                      Image(systemName: "camera")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color(hex: "0x06BAFF"))
                    }
                  }
                  Text(isRecognizing ? "识别中..." : "识别VIN码")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(hex: "0x666666"))
                }
              }
              .frame(maxWidth: .infinity)
              .frame(height: 140)
              .background(Color(hex: "0xF9F9F9"))
              .overlay(
                RoundedRectangle(cornerRadius: 12)
                  .stroke(
                    Color(hex: "0xE5E5E5"),
                    style: StrokeStyle(lineWidth: 1, dash: [5])
                  )
              )
              .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .disabled(isRecognizing)

            // VIN Input
            VStack(alignment: .leading, spacing: 10) {
              Text("VIN信息，一般位于挡风玻璃下方。")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(hex: "0x666666"))

              VinInputView(
                text: $bindingStore.vinText,
                cursorIndex: $vinCursorIndex,
                isFocused: isVinKeyboardVisible,
                onTap: {
                  withAnimation {
                    isVinKeyboardVisible = true
                  }
                  UIApplication.shared.dismissKeyboard()
                }
              )
            }

            // Next Button
            Button {
              validateVinAndNext()
            } label: {
              ZStack {
                RoundedRectangle(cornerRadius: 8)
                  .fill(canSubmit ? ThemeColor.brand500 : ThemeColor.brand500.opacity(0.4))

                if bindingStore.isChecking {
                  ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                  Text("下一步")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                }
              }
              .frame(height: 50)
            }
            .buttonStyle(.plain)
            .disabled(!canSubmit || bindingStore.isChecking)
            .padding(.top, 20)

            // 要有个垫片，高度为1/2屏幕高度
            Spacer(minLength: UIScreen.main.bounds.height / 3)
          }
          .padding(.horizontal, 24)
        }
      }
    }
    .navigationBarHidden(true)
    .navigationBarBackButtonHidden(true)
    .onTapGesture {
      UIApplication.shared.dismissKeyboard()
      withAnimation {
        isVinKeyboardVisible = false
      }
    }
    .overlay(
      Group {
        if isVinKeyboardVisible {
          VStack {
            Spacer()
            VinKeyboard(
              onSelect: { char in
                insertVinCharacter(char)
              },
              onDelete: {
                deleteVinCharacter()
              }
            )
            .transition(.move(edge: .bottom))
          }
        }
      }
    )
    .onAppear {
      cameraPermissionStore.refresh()
      bindingStore.updateCurrentStep(for: 2)
      vinCursorIndex = min(bindingStore.vinText.count, 16)
    }
    .onChange(of: scenePhase) { newValue in
      if newValue == .active {
        cameraPermissionStore.refresh()
      }
    }
    .onChange(of: cameraPermissionStore.authorization) { newValue in
      if shouldPresentCameraAfterAuthorization, newValue == .authorized {
        shouldPresentCameraAfterAuthorization = false
        isPresentingCamera = true
      } else if shouldPresentCameraAfterAuthorization, newValue == .denied || newValue == .restricted {
        shouldPresentCameraAfterAuthorization = false
        ToastCenter.shared.show("请在设置中开启相机权限")
      }
    }
    .onChange(of: bindingStore.vinText) { newValue in
      if newValue.count > 17 {
        bindingStore.vinText = String(newValue.prefix(17))
      }
      vinCursorIndex = min(vinCursorIndex, bindingStore.vinText.count)
      if newValue.count == 17, isVinKeyboardVisible {
        withAnimation {
          isVinKeyboardVisible = false
        }
      }
    }
    .sheet(isPresented: $isPresentingCamera) {
      CameraPicker { image in
        if let image {
          uploadAndRecognize(image)
        }
      }
      .ignoresSafeArea()
    }
    .sheet(isPresented: $isPresentingPhotoPicker) {
      PhotoPicker { image in
        if let image {
          uploadAndRecognize(image)
        }
      }
      .ignoresSafeArea()
    }
    .actionSheet(isPresented: $isPresentingVinSourceSheet) {
      ActionSheet(
        title: Text("选择识别方式"),
        buttons: [
          .default(Text("拍照")) {
            checkCameraPermission()
          },
          .default(Text("从相册选择")) {
            isPresentingPhotoPicker = true
          },
          .cancel(Text("取消")),
        ]
      )
    }
    .alert(isPresented: $isPresentingCameraSettingsAlert) {
      Alert(
        title: Text("需要相机权限"),
        message: Text("请在系统设置中开启相机权限后再使用拍照识别。"),
        primaryButton: .default(Text("去设置")) {
          openAppSettings()
        },
        secondaryButton: .cancel(Text("取消"))
      )
    }
  }

  private var canSubmit: Bool {
    let vin = bindingStore.vinText
    return vin.count == 17
  }

  /// DONE-AI: 已改用 CameraPermissionStore 管理相机权限
  private func checkCameraPermission() {
    cameraPermissionStore.refresh()
    switch cameraPermissionStore.authorization {
    case .authorized:
      isPresentingCamera = true
    case .notDetermined:
      shouldPresentCameraAfterAuthorization = true
      cameraPermissionStore.requestIfNeeded()
    case .denied, .restricted:
      isPresentingCameraSettingsAlert = true
    @unknown default:
      break
    }
  }

  private func presentVinSourceSheet() {
    if isRecognizing { return }
    isPresentingVinSourceSheet = true
  }

  private func openAppSettings() {
    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
    UIApplication.shared.open(url)
  }

  private func validateVinAndNext() {
    let vin = bindingStore.vinText
    if vin.count != 17 {
      ToastCenter.shared.show("请输入17位VIN码")
      return
    }

    Task {
      let isValid = await bindingStore.validateVin()
      await MainActor.run {
        if isValid {
          if let next = bindingStore.nextStepNumber(after: 2) {
            appNavigation.push(bindingStore.enterStep(next))
          }
        } else {
          ToastCenter.shared.show("请检查VIN码是否输入正确")
        }
      }
    }
  }

  private func uploadAndRecognize(_ originResize: UIImage) {
    isRecognizing = true

    let image = originResize.resize(targetWidth: 1024)

    // 压缩图片
    guard let imageData = image.jpegData(compressionQuality: 0.6) else {
      ToastCenter.shared.show("图片处理失败")
      isRecognizing = false
      return
    }

    Task {
      guard let token = await ResourceAPI.shared.getVinSignToken() else {
        await MainActor.run {
          ToastCenter.shared.show("获取上传凭证失败")
          isRecognizing = false
        }
        return
      }

      guard let key = await UploadAPI.shared.uploadImage2QiNiu(
        data: imageData,
        mime: "image/jpeg",
        token: token
      ) else {
        await MainActor.run {
          ToastCenter.shared.show("上传失败")
          isRecognizing = false
        }
        return
      }

      let imageUrl = "\(token.baseUrl)/\(key)"

      if let vinData = await OCRAPI.shared.vin(vinUrl: imageUrl),
         let vin = vinData.vin, !vin.isEmpty
      {
        await MainActor.run {
          bindingStore.vinText = vin
          bindingStore.vinImg = imageUrl
          isRecognizing = false
          ToastCenter.shared.show("识别成功")
        }
      } else {
        await MainActor.run {
          ToastCenter.shared.show("未识别到VIN码")
          isRecognizing = false
        }
      }
    }
  }

  private var safeAreaTop: CGFloat {
    UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0
  }

  private func insertVinCharacter(_ char: String) {
    var chars = Array(bindingStore.vinText)
    let index = min(vinCursorIndex, chars.count)
    if index < chars.count {
      chars[index] = Character(char)
    } else if chars.count < 17 {
      chars.append(Character(char))
    }
    bindingStore.vinText = String(chars)
    if vinCursorIndex < 16 {
      vinCursorIndex = min(index + 1, 16)
    }
  }

  private func deleteVinCharacter() {
    guard vinCursorIndex > 0 else { return }
    var chars = Array(bindingStore.vinText)
    let deleteIndex = min(vinCursorIndex - 1, chars.count - 1)
    chars.remove(at: deleteIndex)
    bindingStore.vinText = String(chars)
    vinCursorIndex = max(0, deleteIndex)
  }
}
