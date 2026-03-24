import SwiftUI

struct FunctionBarView: View {
  @EnvironmentObject private var viewModel: VehicleLiveViewModel

  var body: some View {
    HStack(spacing: 0) {
      if viewModel.liveIsExpanded {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 20) {
            if viewModel.isLiveWifiMode == false {
              itemSystem(icon: "xmark", title: "收起") {
                withAnimation(.easeInOut(duration: 0.2)) {
                  viewModel.liveIsExpanded = false
                }
              }
            }
            item(
              icon: viewModel.liveIsDualCamera ? "icon_live_camera_active" : "icon_live_camera",
              title: "双摄",
              isActive: viewModel.liveIsDualCamera,
              isEnabled: viewModel.isLiveDualCameraEnabled,
              onTap: {
                withAnimation {
                  viewModel.toggleDual()
                }
              }
            )
            item(
              icon: "icon_live_tcard",
              title: "T卡视频",
              isEnabled: viewModel.isTCardReplayEnabled,
              onTap: viewModel.openReplay
            )
          }
          .padding(.horizontal, 12)
        }
      } else {
        functionMenuFab
      }
    }
    .padding(viewModel.liveIsExpanded ? 16 : 2)
    .background(
      RoundedRectangle(cornerRadius: !viewModel.liveIsExpanded ? 24 : 0)
        .fill(Color.white)
        .shadow(color: Color.black.opacity(!viewModel.liveIsExpanded ? 0.1 : 0), radius: 4, x: 0, y: 2)
    )
    .padding(.top, !viewModel.liveIsExpanded ? 16 : 0)
    .padding(.leading, !viewModel.liveIsExpanded ? 16 : 0)
  }

  private func itemSystem(icon: String, title: String, onTap: @escaping () -> Void) -> some View {
    Button {
      onTap()
    } label: {
      VStack(spacing: 8) {
        Image(systemName: icon)
          .resizable()
          .scaledToFit()
          .frame(width: 20, height: 20) // icon 尺寸
          .foregroundColor(Color(hex: "0x666666"))
          .frame(width: 28, height: 28) // 外层 view)

        Text(title)
          .font(.system(size: 12))
          .foregroundColor(Color(hex: "0x666666"))
      }
      .frame(width: 60)
    }
    .buttonStyle(.plain)
  }

  private func item(icon: String, title: String, isActive: Bool = false, isEnabled: Bool = true, onTap: @escaping () -> Void) -> some View {
    Button {
      onTap()
    } label: {
      VStack(spacing: 8) {
        Image(icon)
          .resizable()
          .scaledToFit()
          .frame(width: 28, height: 28)

        Text(title)
          .font(.system(size: 12))
          .foregroundColor(isActive ? ThemeColor.brand500 : Color(hex: "0x666666"))
      }
      .frame(width: 60)
      .opacity(isEnabled ? 1 : 0.35)
    }
    .buttonStyle(.plain)
    .disabled(!isEnabled)
  }

  /// 展开的按钮
  private var functionMenuFab: some View {
    Button {
      withAnimation(.easeInOut(duration: 0.2)) {
        viewModel.liveIsExpanded = true
      }
    } label: {
      Image(systemName: "square.grid.2x2")
        .font(.system(size: 18, weight: .semibold))
        .foregroundColor(Color(hex: "0x333333"))
        .frame(width: 44, height: 44)
    }
    .buttonStyle(.plain)
  }
}
