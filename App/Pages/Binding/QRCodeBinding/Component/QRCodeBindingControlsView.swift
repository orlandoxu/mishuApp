import SwiftUI

struct QRCodeBindingControlsView: View {
  @Binding var torchOn: Bool
  let onTapAlbum: () -> Void

  var body: some View {
    HStack(spacing: 64) {
      ControlButton(
        title: "轻触照亮",
        systemImage: torchOn ? "bolt.fill" : "bolt.slash.fill",
        isActive: torchOn
      ) {
        torchOn.toggle()
      }

      ControlButton(
        title: "选择相册",
        systemImage: "photo.on.rectangle",
        isActive: false
      ) {
        onTapAlbum()
      }
    }
  }
}

struct ControlButton: View {
  let title: String
  let systemImage: String
  let isActive: Bool
  let onTap: () -> Void

  var body: some View {
    Button {
      onTap()
    } label: {
      VStack(spacing: 12) {
        ZStack {
          Circle()
            .fill(isActive ? Color.white : Color.white.opacity(0.2))
            .frame(width: 56, height: 56)
            .overlay(
              Circle().stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 6)

          Image(systemName: systemImage)
            .font(.system(size: 22, weight: .medium))
            .foregroundColor(isActive ? Color(hex: "0x111111") : .white)
        }

        Text(title)
          .font(.system(size: 13, weight: .medium))
          .foregroundColor(.white)
      }
    }
    .buttonStyle(.plain)
  }
}
