import Kingfisher
import SwiftUI

// DONE-AI: 已移除视频右上角图标，统一改为前/后摄文字角标。
// DONE-AI: 角标使用“前/后”短字，避免和视频播放按钮语义重复。
struct SnapPreviewList: View {
  @EnvironmentObject private var vm: VehicleLiveViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 10) {
          if vm.liveCaptureHistory.isEmpty {
            Text("抓拍后会显示在这里")
              .font(.system(size: 16, weight: .semibold))
              .foregroundColor(Color(hex: "0x5E7488"))
              .frame(maxWidth: .infinity, alignment: .leading)
              .frame(height: 56)
              .padding(.horizontal, 8)
          } else {
            ForEach(vm.liveCaptureHistory, id: \.previewKey) { preview in
              Button {
                vm.openPreview(preview)
              } label: {
                ZStack(alignment: .topTrailing) {
                  thumbnail(for: preview)

                  Text(preview.cam == .rear ? "后" : "前")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.55))
                    .clipShape(Capsule())
                    .padding(.top, 3)
                    .padding(.trailing, 9)
                }
                .frame(width: 84, height: 56)
                .overlay(
                  RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected(preview) ? Color(hex: "0x06BAFF") : Color.white.opacity(0.6), lineWidth: isSelected(preview) ? 2 : 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
              }
              .buttonStyle(.plain)
              .transition(
                .asymmetric(
                  insertion: .move(edge: .leading).combined(with: .opacity),
                  removal: .opacity
                )
              )
            }
          }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
      }
      .frame(height: 76)
      .background(
        RoundedRectangle(cornerRadius: 14)
          .fill(Color.white.opacity(0.97))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 14)
          .stroke(Color.white.opacity(0.98), lineWidth: 1.2)
      )
      .shadow(
        color: Color.black.opacity(0.08),
        radius: 8,
        x: 0,
        y: 4
      )

    }
    .padding(.horizontal, 12)
    .padding(.top, 12)
    .animation(.easeInOut(duration: 0.22), value: vm.liveCaptureHistory)
  }

  @ViewBuilder
  private func thumbnail(for preview: LiveCapturePreview) -> some View {
    switch preview.kind {
    case .photo:
      KFImage(preview.url)
        .placeholder {
          Color.black.opacity(0.2)
        }
        .resizable()
        .scaledToFill()
    case .video:
      ZStack {
        Color.black.opacity(0.85)
        Image(systemName: "play.fill")
          .font(.system(size: 16, weight: .bold))
          .foregroundColor(.white.opacity(0.9))
      }
    }
  }

  private func isSelected(_ preview: LiveCapturePreview) -> Bool {
    guard let selected = vm.liveCapturePreview else { return false }
    if let selectedId = selected.id, let previewId = preview.id {
      return selectedId == previewId
    }
    return selected.url.absoluteString == preview.url.absoluteString && selected.kind == preview.kind
  }
}

private extension LiveCapturePreview {
  var previewKey: String {
    if let id, id.isEmpty == false {
      return "id:\(id)"
    }
    return "local:\(kind)-\(cam)-\(url.absoluteString)"
  }
}
