import SwiftUI
import UIKit

struct VehicleLiveView: View {
  let deviceId: String
  @ObservedObject private var appNavigation = AppNavigationModel.shared
  @StateObject private var vm: VehicleLiveViewModel

  init(deviceId: String, entryMode: VehicleLiveEntryMode = .cellular) {
    self.deviceId = deviceId
    _vm = StateObject(wrappedValue: VehicleLiveViewModel(deviceId: deviceId, entryMode: entryMode))
  }

  var body: some View {
    ZStack {
      VStack(spacing: 0) {
        Header4LiveView()

        VideoPlayerView()

        if vm.isLiveWifiMode {
          ZStack(alignment: .topLeading) {
            VStack {
              Spacer().frame(height: vm.liveIsExpanded ? 80 : 0)
              SnapPreviewList()
              MapAreaView()
            }

            FunctionBarView()
              .frame(height: 80)
              .clipped()
          }
        } else {
          ZStack(alignment: .topLeading) {
            VStack {
              Spacer().frame(height: vm.bottomActionStatus == .talkback && vm.liveIsExpanded ? 80 : 0)

              MapAreaView()
            }

            if vm.bottomActionStatus == .talkback {
              FunctionBarView()
                .frame(height: 80)
                .clipped()
            } else {
              SnapPreviewList()
            }
          }
        }
      }
      .background(vm.isLiveWifiMode ? Color(hex: "0xF2F4F7") : Color(hex: "0xEAF4FA"))
    }
    .ignoresSafeArea()
    .navigationBarHidden(true)
    .alert(isPresented: $vm.isExitWifiPreviewConfirmPresented) {
      Alert(
        title: Text("提示"),
        message: Text("确定断开wifi，退出预览？"),
        primaryButton: .destructive(Text("确定")) {
          vm.confirmExit()
        },
        secondaryButton: .cancel(Text("取消"))
      )
    }
    .fullScreenCover(isPresented: $vm.liveIsFullScreenPreviewPresented) {
      if let preview = vm.liveCapturePreview {
        SnapFullPreview(preview: preview) {
          vm.closePreviewFull()
        }
      }
    }
    .environmentObject(vm)
    .taskOnce {
      await vm.prepare()
    }
    .onDisappear {
      let stillInLiveRoute = appNavigation.path.contains { item in
        guard case let .vehicleLive(targetDeviceId, _) = item.route else { return false }
        return targetDeviceId == deviceId
      }
      if stillInLiveRoute {
        return
      }
      vm.cleanExit()
    }
    .onChange(of: vm.isLiveDualCameraEnabled) { _ in
      vm.fixState()
    }
  }
}
