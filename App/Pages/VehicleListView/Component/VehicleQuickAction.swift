import Foundation

enum VehicleQuickAction: CaseIterable, Hashable {
  case cloudService
  case cloudAlbum
  case car
  case more

  var title: String {
    switch self {
    case .cloudService:
      return "云服务"
    case .cloudAlbum:
      return "云相册"
    case .car:
      return "爱车"
    case .more:
      return "更多"
    }
  }

  var iconName: String? {
    switch self {
    case .cloudService:
      return "icon_service_active" // Dynamic logic in view will override this
    case .cloudAlbum:
      return "icon_image"
    case .car:
      return "icon_car"
    case .more:
      return nil // Use system image
    }
  }

  var systemImageName: String {
    switch self {
    case .more:
      return "ellipsis"
    default:
      return ""
    }
  }
}
