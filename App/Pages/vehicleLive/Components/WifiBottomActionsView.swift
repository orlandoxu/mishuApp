import SwiftUI

struct WifiBottomActionsView: View {
  @EnvironmentObject private var vm: VehicleLiveViewModel

  var body: some View {
    VStack(spacing: 0) {
      Spacer()

      Button {
        vm.onTapWifiCaptureAction()
      } label: {
        Circle()
          .fill(centerBtnFill)
          .overlay(
            Circle().stroke(centerBtnStroke, lineWidth: 3)
          )
          .frame(width: 68, height: 68)
        .animation(.easeInOut(duration: 0.18), value: vm.isWifiRecording)
        .animation(.easeInOut(duration: 0.18), value: vm.wifiCaptureActionMode)
      }
      .buttonStyle(.plain)
      .disabled(!vm.isWifiCaptureEnabled)
      .opacity(vm.isWifiCaptureEnabled ? 1 : 0.45)

      Text(centerActionText)
        .font(.system(size: 16, weight: .regular))
        .foregroundColor(centerActionTextColor)
        .padding(.top, 14)

      ModeSwitch(
        selection: $vm.wifiCaptureActionMode,
        items: [
          ModeSwitchItem(title: "照片", mode: WifiCaptureActionMode.photo),
          ModeSwitchItem(title: "视频", mode: WifiCaptureActionMode.video),
        ],
        selectedTextColor: Color(hex: "0x222222"),
        normalTextColor: Color(hex: "0xA3A3A3"),
        pickerWidth: 180,
        pickerHeight: 58,
        isEnabled: !(vm.isSnapshotLoading || vm.isVideoCaptureLoading || vm.isWifiRecording)
      )
      .padding(.top, 24)

      Spacer().frame(height: max(24, safeAreaBottom + 8))
    }
  }

  private var centerActionText: String {
    if let reason = disabledReasonText {
      return reason
    }

    if vm.wifiCaptureActionMode == .video {
      return vm.isWifiRecording ? "录制中，点击结束" : "点击录制"
    }
    return vm.isSnapshotLoading ? "截帧中..." : "点击截帧"
  }

  private var disabledReasonText: String? {
    if vm.isSnapshotLoading || vm.isVideoCaptureLoading || vm.isWifiRecording {
      return nil
    }

    if vm.isAnyLivePlaying == false {
      return "暂无视频播放"
    }

    if vm.isWifiCaptureEnabled == false {
      return "连接中..."
    }

    return nil
  }

  private var centerActionTextColor: Color {
    if disabledReasonText != nil {
      return Color(hex: "0x999999")
    }
    return Color(hex: "0x111111")
  }

  private var centerBtnFill: Color {
    if vm.wifiCaptureActionMode == .video {
      return Color(hex: "0xE53E3E")
    }
    return Color(hex: "0xFF7A00")
  }

  private var centerBtnStroke: Color {
    Color(hex: "0x4B5563")
  }
}
