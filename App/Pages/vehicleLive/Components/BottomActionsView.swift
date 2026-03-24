import SwiftUI

// DONE-AI: 已重命名为 BottomActionsView（类名/文件名对齐）
struct BottomActionsView: View {
  @EnvironmentObject private var vm: VehicleLiveViewModel

  var actionText: String {
    if vm.bottomActionStatus == .talkback {
      if vm.liveIsTalking {
        return "结束对讲"
      } else {
        return "点击对讲"
      }
    }

    if vm.bottomActionStatus == .record {
      if vm.recordIsLoading {
        return "正在抓视频..."
      }
      return "点击抓视频"
    }

    if vm.bottomActionStatus == .snapshot {
      if vm.isSnapshotLoading {
        return "正在抓拍..."
      } else if vm.isEagleSnapshotEnabled {
        return "鹰眼已打开"
      } else {
        return "点击抓拍"
      }
    }
    return ""
  }

  var actionIcon: String {
    if vm.bottomActionStatus == .talkback {
      return "icon_live_mic"
    } else if vm.bottomActionStatus == .record {
      return "icon_live_record"
    } else if vm.bottomActionStatus == .snapshot {
      return "icon_live_snapshot"
    }

    return "icon_live_snapshot"
  }

  var body: some View {
    VStack {
      Spacer()
      HStack(alignment: .bottom, spacing: 20) {
        if vm.bottomActionStatus == .snapshot && vm.isEagleSnapshotSupported {
          actionButton(
            icon: "icon_live_eagle",
            title: "鹰眼",
            isEnabled: true,
            isActive: vm.isEagleSnapshotEnabled,
            onTap: {
              vm.toggleEagle()
            }
          )
        } else {
          actionButton(
            icon: vm.bottomActionStatus == .record ? "icon_live_close" : "icon_live_record",
            title: "抓视频",
            isEnabled: vm.isRecordEnabled,
            onTap: {
              if vm.bottomActionStatus == .record {
                vm.bottomActionStatus = .talkback
              } else {
                vm.bottomActionStatus = .record
              }
            }
          )
        }

        // DONE-AI: 已区分中间按钮样式，抓拍/抓视频颜色不同，避免两个状态同样式。
        VStack {
          Button {
            onTapCenterAction()
          } label: {
            VStack(spacing: 6) {
              Group {
                if centerActionLoading {
                  ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "0x06BAFF")))
                } else {
                  Image(actionIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                }
              }
              .frame(width: 68, height: 68)
              .background(centerBtnFill)
              .overlay(
                Circle()
                  .stroke(centerBtnStroke, lineWidth: 3)
              )
              .clipShape(Circle())
              .contentShape(Circle())

              Text(actionText)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(centerActionTextColor)
            }
          }
          .buttonStyle(.plain)
          .allowsHitTesting(centerActionEnabled && !centerActionLoading)

          // 动态出来的切换按钮
          if vm.bottomActionStatus == .record || vm.bottomActionStatus == .snapshot {
            ModeSwitch(
              selection: $vm.captureCameraMode,
              items: [
                ModeSwitchItem(title: "前摄", mode: .front),
                ModeSwitchItem(title: "后摄", mode: .rear),
              ],
              selectedTextColor: Color(hex: "0x222222"),
              normalTextColor: Color(hex: "0x666666"),
              isEnabled: vm.isLiveDualCameraEnabled
            )
            .padding(.top, 8)
            .padding(.bottom, 21)
          }
        }
        .frame(width: 132)

        actionButton(
          icon: vm.bottomActionStatus == .snapshot ? "icon_live_close" : "icon_live_snapshot",
          title: "抓照片",
          isEnabled: true,
          onTap: {
            if vm.bottomActionStatus == .snapshot {
              vm.bottomActionStatus = .talkback
            } else {
              vm.bottomActionStatus = .snapshot
            }
          }
        )
      }
      .padding(.bottom, safeAreaBottom > 0 ? safeAreaBottom : 20)
    }
    .onDisappear {
      vm.stopTalk()
    }
  }

  private var centerActionEnabled: Bool {
    switch vm.bottomActionStatus {
    case .talkback:
      return vm.isTalkbackEnabled
    case .snapshot:
      return true
    case .record:
      return vm.isRecordEnabled
    }
  }

  private var centerActionTextColor: Color {
    if centerActionEnabled || centerActionLoading {
      return Color(hex: "0x333333")
    }
    return ThemeColor.gray500
  }

  private var centerActionLoading: Bool {
    switch vm.bottomActionStatus {
    case .talkback:
      return vm.liveIsTalkbackLoading
    case .snapshot:
      return vm.isSnapshotLoading
    case .record:
      return vm.recordIsLoading
    }
  }

  private var centerBtnFill: Color {
    switch vm.bottomActionStatus {
    case .talkback:
      return vm.liveIsTalking ? Color(hex: "0x06BAFF") : Color.white
    case .snapshot:
      return Color(hex: "0xFF7A00")
    case .record:
      return Color(hex: "0xE53E3E")
    }
  }

  private var centerBtnStroke: Color {
    switch vm.bottomActionStatus {
    case .talkback:
      return Color(hex: "0xD0D7DE")
    case .snapshot:
      return Color(hex: "0x4B5563")
    case .record:
      return Color(hex: "0x4B5563")
    }
  }

  private func onTapCenterAction() {
    switch vm.bottomActionStatus {
    case .talkback:
      vm.tapTalk()
    case .snapshot:
      vm.onTapSnapshot()
    case .record:
      vm.onTapRecord()
    }
  }

  private func actionButton(
    icon: String,
    title: String,
    isEnabled: Bool = true,
    isActive: Bool = false,
    onTap: @escaping () -> Void = {}
  ) -> some View {
    let iconColor = isEnabled ? .primary : Color(hex: "0xBDBDBD")
    let titleColor = isEnabled ? Color(hex: "0x333333") : ThemeColor.gray500

    return VStack {
      Button {
        withAnimation {
          onTap()
        }
      } label: {
        VStack(spacing: 8) {
          // if isLoading {
          //   ProgressView().progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "0x06BAFF")))
          // } else {
          Image(icon)
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
            .foregroundColor(iconColor)
          // }
        }
        .frame(width: 52, height: 52)
        .contentShape(Circle())
      }
      .frame(width: 52, height: 52)
      .glass4FuncBtn(highlight: isActive)
      // .allowsHitTesting(isEnabled && !isLoading)

      Text(title)
        .font(.system(size: 13))
        .foregroundColor(titleColor)
    }
  }
}
