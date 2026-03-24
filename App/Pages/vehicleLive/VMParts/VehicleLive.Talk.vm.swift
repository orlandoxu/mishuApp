import AVFoundation
import Foundation

@MainActor
extension VehicleLiveViewModel {
  /// 处理“对讲”按钮点击并执行可用性校验。
  func tapTalk() {
    guard isTalkbackEnabled else {
      if shouldShowDeviceOfflinePromptInPlayer {
        ToastCenter.shared.show("设备未在线，无法对讲")
      } else if currLiveDid.isEmpty {
        ToastCenter.shared.show("设备异常，未查询到DID")
      } else if playerIsConnected == false {
        ToastCenter.shared.show("设备连接中，请稍后")
      }
      return
    }
    toggleTalk()
  }

  /// 切换对讲开关（开启或停止）。
  func toggleTalk() {
    if liveIsTalking {
      stopTalk()
    } else {
      startTalk()
    }
  }

  /// 启动对讲流程：权限检查、SDK校验、通道选择并开始发送音频。
  func startTalk() {
    guard liveIsTalkbackLoading == false else { return }
    let did = currLiveDid
    guard did.isEmpty == false else {
      ToastCenter.shared.show("设备异常，未查询到DID")
      return
    }

    liveIsTalkbackLoading = true

    Task {
      let permissionOk = await Self.askMic()
      guard permissionOk else {
        await MainActor.run {
          self.liveIsTalkbackLoading = false
          ToastCenter.shared.show("未获得麦克风权限，无法对讲")
        }
        return
      }

      guard let info = await MainActor.run(body: { SelfStore.shared.selfUser?.userInfoXC }) else {
        await MainActor.run {
          self.liveIsTalkbackLoading = false
          ToastCenter.shared.show("缺少直播登录信息")
        }
        return
      }

      let creds = XCPlayerSDKInitializer.Credentials(
        userId: info.userIdXC,
        sign: info.accessTokenXC,
        glbs: info.glbs,
        iotgw: info.iotgw,
        clientId: info.clientId,
        clientSecret: info.clientSecret
      )

      let ok = await XCPlayerSDKInitializer.shared.ensureXCUserLink(credentials: creds)
      guard ok else {
        await MainActor.run {
          self.liveIsTalkbackLoading = false
          ToastCenter.shared.show("直播SDK初始化失败")
        }
        return
      }

      let channel = await MainActor.run { self.preferredTalkbackChannel }

      do {
        try await liveTalkbackController.start(did: did, channel: channel)
        await MainActor.run {
          self.liveIsTalking = true
          self.liveIsTalkbackLoading = false
        }
      } catch {
        await MainActor.run {
          self.liveIsTalking = false
          self.liveIsTalkbackLoading = false
          ToastCenter.shared.show(error.localizedDescription)
        }
      }
    }
  }

  /// 停止对讲并重置对讲状态。
  func stopTalk() {
    liveTalkbackController.stop()
    liveIsTalking = false
    liveIsTalkbackLoading = false
  }

  /// 请求或检查麦克风权限，返回是否可用于对讲。
  private static func askMic() async -> Bool {
    let session = AVAudioSession.sharedInstance()
    switch session.recordPermission {
    case .granted:
      return true
    case .denied:
      return false
    case .undetermined:
      return await withCheckedContinuation { continuation in
        session.requestRecordPermission { ok in
          continuation.resume(returning: ok)
        }
      }
    @unknown default:
      return false
    }
  }
}
