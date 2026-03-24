import SwiftUI

/// 将更新中遮罩作为通用能力，按需挂到会触发更新的组件上
private struct VehicleSettingsUpdatingOverlayModifier: ViewModifier {
  let isUpdating: Bool
  let paddingHorizontal: CGFloat
  let paddingVertical: CGFloat

  func body(content: Content) -> some View {
    content
      .disabled(isUpdating)
      .overlay(
        Group {
          if isUpdating {
            RoundedRectangle(cornerRadius: 6)
              .fill(Color.black.opacity(0.06))
              .padding(.horizontal, paddingHorizontal)
              .padding(.vertical, paddingVertical)
              .overlay(
                ProgressView()
              )
          }
        }
      )
  }
}

extension View {
  func vehicleSettingsUpdatingOverlay(_ isUpdating: Bool, paddingHorizontal: CGFloat = -10, paddingVertical: CGFloat = -2) -> some View {
    modifier(VehicleSettingsUpdatingOverlayModifier(isUpdating: isUpdating, paddingHorizontal: paddingHorizontal, paddingVertical: paddingVertical))
  }
}
