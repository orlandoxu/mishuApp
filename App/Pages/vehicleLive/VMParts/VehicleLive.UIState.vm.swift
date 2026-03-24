import Foundation
import SwiftUI

@MainActor
extension VehicleLiveViewModel {
  /// 根据设备能力修正页面状态，避免出现不支持的双摄/鹰眼状态。
  func fixState() {
    if isLiveDualCameraEnabled == false {
      liveIsDualCamera = false
      liveIsRearPlaying = false
      captureCameraMode = .front
    }
    if isEagleSnapshotSupported == false {
      isEagleSnapshotEnabled = false
    }
  }

  /// 切换底部区域展开/收起状态。
  func togglePanel() {
    liveIsExpanded.toggle()
  }

  /// 显式设置底部区域展开状态。
  func setPanel(_ expanded: Bool) {
    liveIsExpanded = expanded
  }

  /// 切换双摄播放开关，并在关闭时停掉后摄状态。
  func toggleDual() {
    guard isLiveDualCameraEnabled else { return }
    liveIsDualCamera.toggle()
    if liveIsDualCamera == false {
      liveIsRearPlaying = false
    }
  }

  /// 按目标值设置双摄开关，并处理后摄联动状态。
  func setDual(_ enabled: Bool) {
    if enabled {
      guard isLiveDualCameraEnabled else { return }
      liveIsDualCamera = true
      return
    }
    liveIsDualCamera = false
    liveIsRearPlaying = false
  }

  /// 设置抓拍/录制使用的摄像头模式。
  func setCam(_ mode: LiveCaptureCameraMode) {
    if mode == .rear, isLiveDualCameraEnabled == false { return }
    captureCameraMode = mode
  }

  /// 切换鹰眼抓拍开关（设备支持时生效）。
  func toggleEagle() {
    guard isEagleSnapshotSupported else {
      ToastCenter.shared.show("当前设备不支持鹰眼抓拍")
      return
    }
    isEagleSnapshotEnabled.toggle()
  }

  /// 展示一次抓拍/录制结果，并写入历史列表。
  func showPreview(_ preview: LiveCapturePreview) {
    addPreview(preview)
    liveCapturePreview = preview
    let toastText = preview.kind == .photo ? "照片已保存至本地相册" : "视频已保存至本地相册"
    ToastCenter.shared.show(toastText)
  }

  /// 从历史列表打开某个抓拍预览。
  func openPreview(_ preview: LiveCapturePreview) {
    liveCapturePreview = preview
    liveIsFullScreenPreviewPresented = true
  }

  /// 打开最近一次抓拍结果的全屏预览。
  func openLastPreview() {
    guard let latest = liveCaptureHistory.first else { return }
    liveCapturePreview = latest
    liveIsFullScreenPreviewPresented = true
  }

  /// 打开当前抓拍结果的全屏预览。
  func openPreviewFull() {
    guard liveCapturePreview != nil else { return }
    liveIsFullScreenPreviewPresented = true
  }

  /// 关闭抓拍结果全屏预览。
  func closePreviewFull() {
    liveIsFullScreenPreviewPresented = false
  }

  /// 删除当前正在预览的抓拍结果。
  func removePreview() {
    guard let preview = liveCapturePreview else {
      liveIsFullScreenPreviewPresented = false
      return
    }
    removePreview(preview)
  }

  /// 删除指定抓拍结果（有 id 走接口，无 id 仅本地移除）。
  func removePreview(_ preview: LiveCapturePreview) {
    guard let id = preview.id else {
      dropPreview(preview)
      liveIsFullScreenPreviewPresented = false
      liveCapturePreview = liveCaptureHistory.first
      return
    }

    Task {
      let result = await AlbumAPI.shared.deleteResourceById(id)
      await MainActor.run {
        if result == nil {
          ToastCenter.shared.show("删除失败，请稍后再试")
        } else {
          ToastCenter.shared.show("删除成功")
          self.dropPreview(preview)
        }
        liveIsFullScreenPreviewPresented = false
        liveCapturePreview = liveCaptureHistory.first
      }
    }
  }

  /// 将抓拍结果插入历史头部，并按唯一标识去重。
  // DONE-AI: 已为预览列表增删增加动画，避免界面“瞬间跳变”。
  private func addPreview(_ preview: LiveCapturePreview) {
    withAnimation(.easeInOut(duration: 0.2)) {
      liveCaptureHistory.removeAll(where: { samePreview($0, preview) })
      liveCaptureHistory.insert(preview, at: 0)
    }
  }

  /// 从历史列表中移除指定抓拍结果。
  private func dropPreview(_ preview: LiveCapturePreview) {
    withAnimation(.easeInOut(duration: 0.2)) {
      liveCaptureHistory.removeAll(where: { samePreview($0, preview) })
    }
  }

  /// 判断两个抓拍结果是否为同一条记录。
  private func samePreview(_ lhs: LiveCapturePreview, _ rhs: LiveCapturePreview) -> Bool {
    if let lhsId = lhs.id, let rhsId = rhs.id {
      return lhsId == rhsId
    }
    return lhs.url.absoluteString == rhs.url.absoluteString && lhs.kind == rhs.kind
  }
}
