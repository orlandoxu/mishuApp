import SwiftUI

struct TCardControlBarView: View {
  @EnvironmentObject private var viewModel: TCardReplayViewModel

  var body: some View {
    HStack(spacing: 0) {
      TCardActionButton(iconName: "camera", title: "截图", onTap: onSnapshot)
      TCardActionButton(
        iconName: viewModel.tCardIsRecording ? "record.circle" : "video",
        title: "录像",
        accentColor: viewModel.tCardIsRecording ? Color.red : Color(hex: "0x666666"),
        onTap: onRecord
      )
      TCardActionButton(iconName: "photo", title: "相册", onTap: onAlbum)
      if viewModel.tCardCanDownloadInCurrentMode {
        TCardActionButton(iconName: "arrow.down.to.line", title: "下载", onTap: onDownload)
      }
    }
    .padding(.vertical, 8)
    .background(Color.white)
  }

  private func onSnapshot() {
    Task { @MainActor in
      let ok = await viewModel.captureTCardScreenshot()
      ToastCenter.shared.show(ok ? "截图已保存" : "截图失败")
    }
  }

  private func onRecord() {
    Task { @MainActor in
      let ok = await viewModel.toggleTCardRecording()
      ToastCenter.shared.show(ok ? (viewModel.tCardIsRecording ? "开始录制" : "已保存录像") : "录像失败")
    }
  }

  private func onAlbum() {
    ToastCenter.shared.show("即将上线")
  }

  private func onDownload() {
    Task { @MainActor in
      let result = await viewModel.downloadCurrentTCardVideo()
      switch result {
      case .success:
        ToastCenter.shared.show("下载成功")
      case .cancelled:
        ToastCenter.shared.show("已取消下载")
      case .failed(let message):
        ToastCenter.shared.show(message.isEmpty ? "下载失败，请稍后重试" : message)
      }
    }
  }
}

struct TCardActionButton: View {
  let iconName: String
  let title: String
  var accentColor: Color = .init(hex: "0x666666")
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      VStack(spacing: 4) {
        Image(systemName: iconName)
          .font(.system(size: 26))
          .foregroundColor(accentColor)
          .frame(height: 28)

        Text(title)
          .font(.system(size: 12))
          .foregroundColor(Color(hex: "0x666666"))
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 6)
    }
    .buttonStyle(.plain)
  }
}
