import AMapFoundationKit
import AMapSearchKit
import CoreLocation
import MAMapKit
import SwiftUI
import UIKit

// 车辆直播页的高德地图渲染入口（SwiftUI -> MAMapView），负责车辆/用户点位与视口联动

struct Map4Live: UIViewRepresentable {
  let center: CLLocationCoordinate2D?
  let heading: Double?
  let userCoordinate: CLLocationCoordinate2D?
  let userHeading: Double?
  let onlineStatus: Int?
  let statusIconName: String?
  let statusDescription: String?
  let statusColor: UIColor
  let zoomLevel: CGFloat

  init(
    center: CLLocationCoordinate2D? = nil,
    heading: Double? = nil,
    userCoordinate: CLLocationCoordinate2D? = nil,
    userHeading: Double? = nil,
    onlineStatus: Int? = nil,
    statusIconName: String? = nil,
    statusDescription: String? = nil,
    statusColor: UIColor = ThemeColor.gray600Ui,
    zoomLevel: CGFloat = 15
  ) {
    self.center = center
    self.heading = heading
    self.userCoordinate = userCoordinate
    self.userHeading = userHeading
    self.onlineStatus = onlineStatus
    self.statusIconName = statusIconName
    self.statusDescription = statusDescription
    self.statusColor = statusColor
    self.zoomLevel = zoomLevel
  }

  func makeCoordinator() -> Map4LiveCoordinator {
    // Step 1. 创建并返回 Coordinator（承接 MAMapViewDelegate + AMapSearchDelegate）
    Map4LiveCoordinator()
  }

  func makeUIView(context: Context) -> MAMapView {
    // Step 1. 初始化高德 SDK（Key + 隐私合规）
    VehicleLiveMapBootstrap.setupIfNeeded()

    // Step 2. 构建地图视图
    let mapView = MAMapView(frame: .zero)
    mapView.delegate = context.coordinator
    context.coordinator.mapView = mapView
    mapView.showsCompass = false
    mapView.showsScale = false
    mapView.isRotateEnabled = false
    mapView.isRotateCameraEnabled = false
    context.coordinator.performProgrammaticViewportChange {
      mapView.zoomLevel = zoomLevel
    }

    // Step 3. 初始化视口（车辆优先）
    if let center, !context.coordinator.didFitToVehicle {
      context.coordinator.didFitToVehicle = true
      context.coordinator.performProgrammaticViewportChange {
        mapView.setCenter(center, animated: false)
      }
    }

    return mapView
  }

  func updateUIView(_ uiView: MAMapView, context: Context) {
    let viewportEdgeInsets = Map4LiveCoordinator.routeViewportEdgeInsets
    let hasRouteViewport = context.coordinator.routePolyline != nil
    let hasDualPointViewport = (center != nil && userCoordinate != nil)
    let shouldKeepFittedViewport = hasRouteViewport || hasDualPointViewport

    // Step 1. 同步缩放等级（外部状态变化 -> 地图缩放）
    if context.coordinator.isViewportLocked == false {
      let shouldAnimateRestore = context.coordinator.consumeRestoreAnimationIfNeeded()
      if shouldAnimateRestore {
        context.coordinator.performProgrammaticViewportChange {
          if let routePolyline = context.coordinator.routePolyline {
            uiView.setVisibleMapRect(
              routePolyline.boundingMapRect,
              edgePadding: viewportEdgeInsets,
              animated: true
            )
          } else if let center, let userCoordinate {
            var coordinates = [center, userCoordinate]
            if let polyline = MAPolyline(coordinates: &coordinates, count: 2) {
              uiView.setVisibleMapRect(
                polyline.boundingMapRect,
                edgePadding: viewportEdgeInsets,
                animated: true
              )
            } else {
              uiView.setCenter(center, animated: true)
              uiView.setZoomLevel(zoomLevel, animated: true)
            }
          } else if let center {
            uiView.setCenter(center, animated: true)
            uiView.setZoomLevel(zoomLevel, animated: true)
          } else if let userCoordinate {
            uiView.setCenter(userCoordinate, animated: true)
            uiView.setZoomLevel(zoomLevel, animated: true)
          } else {
            uiView.setZoomLevel(zoomLevel, animated: true)
          }
        }
      } else if shouldKeepFittedViewport == false, uiView.zoomLevel != zoomLevel {
        context.coordinator.performProgrammaticViewportChange {
          uiView.setZoomLevel(zoomLevel, animated: false)
        }
      }
    }

    // Step 2. 处理车辆点位（新增 / 更新 / 移除）
    if let center {
      if context.coordinator.carAnnotation == nil {
        let annotation = LiveVehiclePointAnnotation()
        annotation.coordinate = center
        uiView.addAnnotation(annotation)
        context.coordinator.carAnnotation = annotation
      } else {
        context.coordinator.carAnnotation?.coordinate = center
      }
    } else if let annotation = context.coordinator.carAnnotation {
      uiView.removeAnnotation(annotation)
      context.coordinator.carAnnotation = nil
      context.coordinator.carAnnotationView = nil
    }

    // Step 3. 处理用户点位（新增 / 更新 / 移除）
    if let userCoordinate {
      if context.coordinator.userAnnotation == nil {
        let annotation = LiveUserPointAnnotation()
        annotation.coordinate = userCoordinate
        uiView.addAnnotation(annotation)
        context.coordinator.userAnnotation = annotation
      } else {
        context.coordinator.userAnnotation?.coordinate = userCoordinate
      }
    } else if let annotation = context.coordinator.userAnnotation {
      uiView.removeAnnotation(annotation)
      context.coordinator.userAnnotation = nil
      context.coordinator.userAnnotationView = nil
    }

    // Step 4. 同步业务状态到 Coordinator（用于标注视图渲染）
    context.coordinator.userHeading = userHeading
    context.coordinator.heading = heading
    context.coordinator.onlineStatus = onlineStatus
    context.coordinator.statusIconName = statusIconName
    context.coordinator.statusDescription = statusDescription
    context.coordinator.statusColor = statusColor

    // Step 5. 如果标注视图已创建，则即时刷新 UI（避免等待重用回调）
    if let view = context.coordinator.carAnnotationView {
      view.updateHeading(heading)
      view.updateOnlineStatus(onlineStatus)
      view.updateStatus(iconName: statusIconName, description: statusDescription, color: statusColor)
    }
    if let view = context.coordinator.userAnnotationView {
      view.updateHeading(userHeading)
    }

    // Step 6. 首次适配视口（车辆优先，其次车辆+用户）
    context.coordinator.fitViewportIfNeeded(vehicle: center, user: userCoordinate)

    // Step 7. 首次尝试规划路线（仅一次，避免多次请求）
    context.coordinator.planRouteIfNeeded(vehicle: center, user: userCoordinate)
  }
}
