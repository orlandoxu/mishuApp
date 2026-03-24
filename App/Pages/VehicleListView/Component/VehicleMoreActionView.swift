import SwiftUI

enum VehicleMoreActionView: CaseIterable, Hashable {
  case wifiDirect
  case carBrand
  case unbind
  case settings
  case simCard

  var title: String {
    switch self {
    case .wifiDirect: return "wifi直连"
    case .carBrand: return "车辆信息"
    case .unbind: return "解绑设备"
    case .settings: return "设置"
    case .simCard: return "SIM卡"
    }
  }

  var iconName: String {
    switch self {
    case .wifiDirect: return "icon_wifi"
    case .carBrand: return "icon_car_brand"
    case .unbind: return "icon_unlink"
    case .settings: return "icon_settings"
    case .simCard: return "icon_sim"
    }
  }
}

struct EquipmentMoreSheet: View {
  let vehicle: VehicleModel
  let onAction: (VehicleMoreActionView) -> Void
  let onCancel: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      Text("更多")
        .font(.system(size: 18, weight: .bold))
        .foregroundColor(Color(hex: "0x111111"))
        .padding(.top, 24)
        .padding(.bottom, 20)

      LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 24) {
        ForEach(actions, id: \.self) { action in
          Button {
            onAction(action)
          } label: {
            VStack(spacing: 10) {
              ZStack {
                RoundedRectangle(cornerRadius: 16)
                  .fill(ThemeColor.gray100)
                  .frame(width: 56, height: 56)

                Image(action.iconName)
                  .resizable()
                  .scaledToFit()
                  .frame(width: 30, height: 30)
              }

              Text(action.title)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "0x666666"))
            }
          }
          .buttonStyle(.plain)
        }

        if actions.count <= 4 {
          Spacer().frame(height: 42)
        }
      }
      .padding(.horizontal, 24)
      .padding(.bottom, safeAreaBottom + 24)
    }
    .frame(maxWidth: .infinity)
    .background(Color.white)
    .cornerRadius(24)
  }

  private var safeAreaBottom: CGFloat {
    UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
  }

  private var titleText: String {
    "更多"
  }

  private var actions: [VehicleMoreActionView] {
    var items = VehicleMoreActionView.allCases
    if vehicle.sim?.thirdUrl.isEmpty ?? true {
      items.removeAll { $0 == .simCard }
    }
    return items
  }
}
