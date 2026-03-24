import AVFoundation
import SwiftUI
import UIKit
import Vision

struct QRCodeBinding: View {
  @ObservedObject private var appNavigation = AppNavigationModel.shared
  @Environment(\.scenePhase) private var scenePhase

  @StateObject private var bindingStore: BindingStore = .shared

  private enum Constants {
    static let scanLineStartOffset: CGFloat = 10
    static let scanLineEndOffset: CGFloat = 246
    static let scanLineDelay: TimeInterval = 0.1
    static let scanLineDuration: TimeInterval = 2
    static let restartDelayOnAppear: TimeInterval = 0.1
    static let restartDelayAfterAuthorization: TimeInterval = 0.2
    static let manualBindDelay: TimeInterval = 0.35
    static let scanThrottleInterval: TimeInterval = 2
    static let cameraOverlayOpacity: Double = 0.2
  }

  @State private var cameraAuthorization: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
  @State private var scannerViewID: UUID = .init()
  @State private var torchOn: Bool = false
  @State private var isPresentingPhotoPicker: Bool = false
  @State private var isBinding: Bool = false // 是否在绑定过程中
  @State private var lastHandledCode: String = ""
  @State private var lastHandledAt: Date = .distantPast
  @State private var scanLineOffset: CGFloat = Constants.scanLineStartOffset
  @State private var didStartScanLine: Bool = false
  @State private var didHandleInitialQRCode: Bool = false
  @State private var showCameraPermissionAlert: Bool = false

  var body: some View {
    ZStack {
      // 最底部一层，摄像头全屏显示层
      CameraLayer(
        authorization: cameraAuthorization,
        scannerViewID: scannerViewID,
        torchOn: $torchOn,
        onScanned: handleScannedCode
      )
      .overlay(Color.black.opacity(Constants.cameraOverlayOpacity))
      .ignoresSafeArea()

      // 设置按钮层
      VStack(spacing: 0) {
        QRCodeBindingHeaderView {
          appNavigation.pop()
        }

        Spacer(minLength: 0)

        VStack(spacing: 0) {
          // 扫码指示区域
          QRCodeBindingScanFrameView(scanLineOffset: scanLineOffset)

          // 两个操作按钮
          QRCodeBindingControlsView(torchOn: $torchOn) {
            isPresentingPhotoPicker = true
          }
          .padding(.bottom, 40)
          .padding(.top, 80)
        }
        .padding(.bottom, 80)

        Spacer(minLength: 0)
      }
      .padding(.horizontal, 16)

      // 手动绑定跳转按钮，单独一层（目的是放在对底部）
      VStack {
        Spacer()
        QRCodeBindingBottomBarView {
          replaceToManualBind()
        }
        .padding(.horizontal, 24)
        .padding(.bottom, safeAreaBottom + 12)
      }
    }
    .navigationBarHidden(true)
    .navigationBarBackButtonHidden(true)
    .sheet(isPresented: $isPresentingPhotoPicker) {
      PhotoPicker { image in
        if let image {
          recognizeQRCode(from: image)
        }
      }
      .ignoresSafeArea()
    }
    .onAppear {
      updateCameraAuthorization(forceRestartScanner: true)
    }
    .onChange(of: scenePhase) { newValue in
      if newValue == .active {
        updateCameraAuthorization(forceRestartScanner: true)
      }
    }
    .onChange(of: cameraAuthorization) { newValue in
      if newValue == .authorized {
        handleAuthorizedState(restartDelay: Constants.restartDelayAfterAuthorization)
      }
    }
    .onChange(of: torchOn) { _ in
      handleTorchToggleChange()
    }
    .alert(isPresented: $showCameraPermissionAlert) {
      Alert(
        title: Text("需要相机权限"),
        message: Text("请在系统设置中开启相机权限后再使用扫码功能。"),
        primaryButton: .default(Text("去设置")) {
          openAppSettings()
        },
        secondaryButton: .cancel(Text("取消"))
      )
    }
  }

  private func updateCameraAuthorization(forceRestartScanner: Bool = false) {
    // Step 1. 获取最新相机权限
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    cameraAuthorization = status
    if status == .authorized {
      // Step 2. 已授权时更新扫描状态
      let delay = forceRestartScanner ? Constants.restartDelayOnAppear : nil
      handleAuthorizedState(restartDelay: delay)
      return
    }
    if status == .notDetermined {
      // Step 3. 未询问时触发系统授权弹窗
      AVCaptureDevice.requestAccess(for: .video) { granted in
        DispatchQueue.main.async {
          cameraAuthorization = granted ? .authorized : .denied
          if granted {
            self.handleAuthorizedState(restartDelay: Constants.restartDelayAfterAuthorization)
          } else {
            ToastCenter.shared.show("未授权相机权限")
            self.showCameraPermissionAlert = true
          }
        }
      }
      return
    }
    // Step 4. 其它状态提示无权限
    // ToastCenter.shared.show("没有相机权限")
    showCameraPermissionAlert = true
  }

  private func handleAuthorizedState(restartDelay: TimeInterval?) {
    // Step 1. 根据需要重建扫码视图
    if let restartDelay {
      restartScanner(after: restartDelay)
    }
    // Step 2. 启动扫描线动画
    startScanLineAnimationIfNeeded()
  }

  private func handleTorchToggleChange() {
    // Step 1. 无权限时回退开关
    if cameraAuthorization != .authorized {
      torchOn = false
      // Step 2. 弹出提示
      ToastCenter.shared.show("没有相机权限，无法开启照明")
    }
  }

  private func openAppSettings() {
    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
    UIApplication.shared.open(url)
  }

  private func startScanLineAnimationIfNeeded() {
    // Step 1. 防止重复启动动画
    if didStartScanLine { return }
    didStartScanLine = true
    // Step 2. 重置扫描线起点
    scanLineOffset = Constants.scanLineStartOffset
    // Step 3. 延迟启动动画并循环移动
    DispatchQueue.main.asyncAfter(deadline: .now() + Constants.scanLineDelay) {
      withAnimation(.easeInOut(duration: Constants.scanLineDuration).repeatForever(autoreverses: false)) {
        scanLineOffset = Constants.scanLineEndOffset
      }
    }
  }

  /// 识别到了二维码的时候，回调函数
  private func handleScannedCode(_ raw: String) {
    // Step 1. 规范化二维码内容
    let code = trimmedQRCode(raw)
    if code.isEmpty {
      LKLog("scan qr empty result", type: "user", label: "warning")
      return
    }
    // Step 2. 过滤重复和绑定中状态
    guard shouldHandleQRCode(code) else {
      LKLog("scan qr ignored reason=throttled_or_binding", type: "user", label: "debug")
      return
    }
    // Step 3. 更新最近处理记录并触发绑定
    lastHandledCode = code
    lastHandledAt = Date()
    LKLog("scan qr captured summary=\(codeSummary(code))", type: "user", label: "info")

    // Step 4. 触发绑定流程
    bindByQRCode(code)
  }

  private func bindByQRCode(_ qrcode: String) {
    // Step 1. 防止重复绑定
    if isBinding { return }
    isBinding = true

    Task {
      // Step 2. 解析二维码内容（支持 imei/sn 二维码与普通 qrCode）
      guard let payload = parseBindingQRCodePayload(qrcode) else {
        LKLog("scan qr parse failed", type: "user", label: "warning")
        await MainActor.run {
          isBinding = false
          ToastCenter.shared.show("请扫描正确的绑定二维码")
        }
        return
      }

      let canBind: CanBindVehicleData?
      switch payload {
      case let .imeiSn(imei, sn):
        LKLog("scan qr bind imei_sn imeiLength=\(imei.count) snLength=\(sn.count)", type: "user", label: "info")
        // Step 3. imei/sn 格式二维码：走 imei+sn 校验
        canBind = await UserAPI.shared.canBindVehicle(imei: imei, sn: sn)
      case let .qrCode(code):
        LKLog("scan qr bind qrcode summary=\(codeSummary(code))", type: "user", label: "info")
        // Step 3. 普通二维码：走 qrCode 校验
        canBind = await UserAPI.shared.canBindVehicle(code)
      }

      guard let canBind else {
        LKLog("scan qr canBind failed", type: "user", label: "warning")
        await MainActor.run {
          isBinding = false
        }
        return
      }

      // Step 4. 同手动绑定的校验逻辑保持一致（OBD 必须走 Wifi 绑定）
      if canBind.isObdDevice == 1 {
        LKLog("scan qr blocked by obd device", type: "user", label: "warning")
        await MainActor.run {
          isBinding = false
          ToastCenter.shared.show("OBD设备，请使用Wifi绑定")
        }
        return
      }

      // Step 5. 重置绑定状态并带入 imei/sn，进入车辆信息录入流程
      await MainActor.run {
        isBinding = false
        BindingStore.shared.resetStore(bindingType: .qrCode)
        BindingStore.shared.applyCanBindVehicleData(canBind)
        LKLog(
          "scan qr bind success nextRoute=\(String(describing: BindingStore.shared.recommendedNextStepRoute()))",
          type: "user",
          label: "info"
        )
        appNavigation.replaceTop(with: BindingStore.shared.recommendedNextStepRoute())
      }
    }
  }

  /// 使用照片识别二维码
  private func recognizeQRCode(from image: UIImage) {
    // Step 1. 校验图片
    guard let cgImage = image.cgImage else {
      LKLog("photo qr parse failed reason=cgImage nil", type: "user", label: "error")
      ToastCenter.shared.show("图片解析失败")
      return
    }

    // Step 2. 创建二维码识别请求
    let request = VNDetectBarcodesRequest { request, _ in
      let results = (request.results as? [VNBarcodeObservation]) ?? []
      let code = results.first(where: { $0.symbology == .QR })?.payloadStringValue ?? results.first?.payloadStringValue
      DispatchQueue.main.async {
        guard let code else {
          LKLog("photo qr no code detected", type: "user", label: "warning")
          ToastCenter.shared.show("未识别到二维码")
          return
        }
        handleScannedCode(code)
      }
    }
    request.symbologies = [.QR]

    // Step 3. 异步执行识别
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        try handler.perform([request])
      } catch {
        DispatchQueue.main.async {
          LKLog("photo qr detect error error=\(error.localizedDescription)", type: "user", label: "error")
          ToastCenter.shared.show("识别失败")
        }
      }
    }
  }

  private func restartScanner(after delay: TimeInterval) {
    // Step 1. 延迟重建扫码视图
    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
      scannerViewID = UUID()
    }
  }

  private func replaceToManualBind() {
    // Step 1. 替换当前页面为手动绑定页
    appNavigation.replaceTop(with: .manualBind)
  }

  private func errorMessage(_ error: Error) -> String {
    // Step 1. 优先解析业务错误
    if let businessError = error as? BusinessError {
      return businessError.message.isEmpty ? "请求失败，请稍后再试" : businessError.message
    }
    // Step 2. 解析 API 错误
    if let apiError = error as? UserAPIError {
      switch apiError {
      case let .serverMessage(message):
        return message.isEmpty ? "请求失败，请稍后再试" : message
      case .missingData:
        return "请求失败，请稍后再试"
      }
    }
    // Step 3. 兜底提示
    return "请求失败，请稍后再试"
  }

  private func shouldHandleQRCode(_ code: String) -> Bool {
    // Step 1. 拦截绑定中状态
    if isBinding { return false }
    // Step 2. 拦截短时间重复二维码
    let now = Date()
    if code == lastHandledCode, now.timeIntervalSince(lastHandledAt) < Constants.scanThrottleInterval {
      return false
    }
    return true
  }

  private func trimmedQRCode(_ code: String) -> String {
    code.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func codeSummary(_ code: String) -> String {
    let length = code.count
    let prefix = String(code.prefix(8))
    return "len=\(length),prefix=\(prefix)"
  }

  private enum BindingQRCodePayload {
    case imeiSn(String, String)
    case qrCode(String)
  }

  private func parseBindingQRCodePayload(_ raw: String) -> BindingQRCodePayload? {
    // Step 1. 先做基础规范化（trim + 去除首尾不可见字符 + percent decode）
    let trimmed = trimmedQRCode(raw)
    if trimmed.isEmpty { return nil }
    let decoded = trimmed.removingPercentEncoding ?? trimmed

    // Step 2. 优先解析 imei_XXX@sn_YYY 这种短码格式
    if let pair = parseImeiSnShortCode(decoded) {
      return .imeiSn(pair.imei, pair.sn)
    }

    // Step 3. 回退为原始字符串
    return .qrCode(decoded)
  }

  private func parseImeiSnShortCode(_ code: String) -> (imei: String, sn: String)? {
    // Step 1. 去除空白并统一大小写，降低格式抖动带来的解析失败
    let normalized = code.trimmingCharacters(in: .whitespacesAndNewlines)
    if normalized.count < 10 { return nil }

    // Step 2. 仅处理 imei_ 开头的短码：imei_865...@sn_523...
    guard normalized.lowercased().hasPrefix("imei_") else { return nil }
    let parts = normalized.split(separator: "@", omittingEmptySubsequences: true)
    if parts.count != 2 { return nil }

    // Step 3. 分别解析 imei 与 sn 段
    let imeiPart = String(parts[0])
    let snPart = String(parts[1])

    guard imeiPart.lowercased().hasPrefix("imei_") else { return nil }
    guard snPart.lowercased().hasPrefix("sn_") else { return nil }

    let imei = String(imeiPart.dropFirst("imei_".count))
    let sn = String(snPart.dropFirst("sn_".count))

    // Step 4. 只保留数字，避免扫码内容夹杂空格/换行/前后缀
    let imeiDigits = imei.filter(\.isNumber)
    let snDigits = sn.filter(\.isNumber)

    guard imeiDigits.count >= 10, snDigits.count >= 6 else { return nil }
    return (imei: imeiDigits, sn: snDigits)
  }
}
