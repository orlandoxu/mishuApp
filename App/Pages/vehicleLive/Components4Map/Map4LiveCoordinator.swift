import AMapSearchKit
import CoreLocation
import MAMapKit
import UIKit

// Map4Live 的委托与状态容器，负责 annotation 渲染、路线规划与视口适配

final class Map4LiveCoordinator: NSObject, MAMapViewDelegate, AMapSearchDelegate {
  // 线路视口边距：适当放大边距，避免车/人标注贴边或被遮挡
  static let routeViewportEdgeInsets = UIEdgeInsets(top: 110, left: 56, bottom: 120, right: 56)

  weak var mapView: MAMapView?

  var didFitToVehicle = false
  var didFitToUserAndVehicle = false
  var didFitToRoute = false
  var didAttemptPlanRoute = false

  var carAnnotation: LiveVehiclePointAnnotation?
  var carAnnotationView: Map4LiveCarAnnotationView?
  var userAnnotation: LiveUserPointAnnotation?
  var userAnnotationView: Map4LiveUserAnnotationView?
  var routePolyline: MAPolyline?
  var searchApi: AMapSearchAPI?

  var heading: Double?
  var userHeading: Double?
  var onlineStatus: Int?
  var statusIconName: String?
  var statusDescription: String?
  var statusColor: UIColor = ThemeColor.gray600Ui
  var viewportLockUntil: Date?
  private var pendingSmoothViewportRestore: Bool = false

  private var programmaticViewportChangeDepth: Int = 0

  var isViewportLocked: Bool {
    guard let viewportLockUntil else { return false }
    return Date() < viewportLockUntil
  }

  func lockViewportForUserInteraction(seconds: TimeInterval = 3.5) {
    viewportLockUntil = Date().addingTimeInterval(seconds)
    pendingSmoothViewportRestore = true
  }

  func consumeRestoreAnimationIfNeeded() -> Bool {
    guard !isViewportLocked else { return false }
    guard pendingSmoothViewportRestore else { return false }
    pendingSmoothViewportRestore = false
    return true
  }

  func performProgrammaticViewportChange(_ action: () -> Void) {
    programmaticViewportChangeDepth += 1
    action()
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      self.programmaticViewportChangeDepth = max(0, self.programmaticViewportChangeDepth - 1)
    }
  }

  func mapView(_ mapView: MAMapView!, viewFor annotation: MAAnnotation!) -> MAAnnotationView! {
    // Step 1. 车辆标注：创建/复用车辆标注视图，并同步状态（方向、在线状态、文案）
    if annotation is LiveVehiclePointAnnotation {
      let reuseIdentifier = "vehicleLiveCarAnnotation"
      let annotationView =
        (mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) as? Map4LiveCarAnnotationView)
          ?? Map4LiveCarAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
      annotationView.annotation = annotation
      annotationView.canShowCallout = false
      carAnnotationView = annotationView
      annotationView.updateHeading(heading)
      annotationView.updateOnlineStatus(onlineStatus)
      annotationView.updateStatus(iconName: statusIconName, description: statusDescription, color: statusColor)
      return annotationView
    }

    // Step 2. 用户标注：创建/复用用户标注视图，并同步用户朝向
    if annotation is LiveUserPointAnnotation {
      let reuseIdentifier = "vehicleLiveUserAnnotation"
      let annotationView =
        (mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) as? Map4LiveUserAnnotationView)
          ?? Map4LiveUserAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
      annotationView.annotation = annotation
      annotationView.canShowCallout = false
      userAnnotationView = annotationView
      annotationView.updateHeading(userHeading)
      return annotationView
    }
    return nil
  }

  func mapView(_: MAMapView!, rendererFor overlay: MAOverlay!) -> MAOverlayRenderer! {
    // Step 1. 路线 overlay：仅渲染 MAPolyline，其他 overlay 不处理
    if let polyline = overlay as? MAPolyline {
      let renderer = MAPolylineRenderer(polyline: polyline)
      renderer?.lineWidth = 6
      renderer?.strokeColor = UIColor(ThemeColor.brand500).withAlphaComponent(0.98)
      renderer?.lineJoinType = kMALineJoinRound
      renderer?.lineCapType = kMALineCapRound
      return renderer
    }
    return nil
  }

  func mapView(_: MAMapView!, regionDidChangeAnimated _: Bool) {
    // 仅用户手势触发时进入锁定，避免程序主动调整后误锁定
    if programmaticViewportChangeDepth > 0 { return }
    lockViewportForUserInteraction(seconds: 3.5)
  }

  func fitViewportIfNeeded(vehicle: CLLocationCoordinate2D?, user: CLLocationCoordinate2D?) {
    // Step 1. 获取必要参数
    guard let mapView else { return }
    if isViewportLocked { return }

    // Step 2. 仅车辆存在时，首次居中车辆
    if let vehicle, user == nil, !didFitToVehicle {
      didFitToVehicle = true
      performProgrammaticViewportChange {
        mapView.setCenter(vehicle, animated: false)
      }
      return
    }

    // Step 3. 用户与车辆都存在时，首次适配到两点范围
    guard let vehicle, let user else { return }
    if didFitToUserAndVehicle || didFitToRoute { return }
    didFitToUserAndVehicle = true

    var coordinates = [vehicle, user]
    guard let polyline = MAPolyline(coordinates: &coordinates, count: 2) else { return }
    let rect = polyline.boundingMapRect
    performProgrammaticViewportChange {
      mapView.setVisibleMapRect(
        rect,
        edgePadding: Self.routeViewportEdgeInsets,
        animated: false
      )
    }
  }

  func planRouteIfNeeded(vehicle: CLLocationCoordinate2D?, user: CLLocationCoordinate2D?) {
    // Step 1. 防重复与数据校验
    if didAttemptPlanRoute { return }
    if routePolyline != nil { return }
    guard let vehicle, let user else { return }

    // Step 2. 初始化搜索实例（一次）
    if searchApi == nil {
      guard let api = AMapSearchAPI() else { return }
      api.delegate = self
      searchApi = api
    }

    // Step 3. 发起驾车路线规划（仅一次，避免产生多次计费）
    // 说明：当前 AMapSearchKit 版本使用 AMapDrivingCalRouteSearchRequest + AMapDrivingV2RouteSearch
    didAttemptPlanRoute = true
    let request = AMapDrivingCalRouteSearchRequest()
    request.origin = AMapGeoPoint.location(withLatitude: CGFloat(user.latitude), longitude: CGFloat(user.longitude))
    request.destination = AMapGeoPoint.location(withLatitude: CGFloat(vehicle.latitude), longitude: CGFloat(vehicle.longitude))
    // Step 4. 控制返回字段：尽量请求 polyline，用于绘制路线（rawValue 对应 showFieldTypePolyline）
    if let showFieldType = AMapDrivingRouteShowFieldType(rawValue: 1 << 5) {
      request.showFieldType = showFieldType
    }
    searchApi?.aMapDrivingV2RouteSearch(request)
  }

  func onRouteSearchDone(_: AMapRouteSearchBaseRequest!, response: AMapRouteSearchResponse!) {
    // Step 1. 防止重复绘制
    if routePolyline != nil { return }
    guard let mapView else { return }

    // Step 2. 解析返回路径坐标
    guard
      let route = response.route,
      let path = route.paths.first as? AMapPath,
      let steps = path.steps as? [AMapStep]
    else { return }

    var coordinates: [CLLocationCoordinate2D] = []
    for step in steps {
      let parsed = parsePolyline(step.polyline)
      if !parsed.isEmpty {
        coordinates.append(contentsOf: parsed)
      }
    }
    if coordinates.count < 2 { return }

    // Step 3. 绘制路线 overlay，并适配视口（仅一次）
    var coords = coordinates
    guard let polyline = MAPolyline(coordinates: &coords, count: UInt(coords.count)) else { return }
    routePolyline = polyline
    mapView.add(polyline)

    if !didFitToRoute {
      if isViewportLocked { return }
      didFitToRoute = true
      let rect = polyline.boundingMapRect
      performProgrammaticViewportChange {
        mapView.setVisibleMapRect(
          rect,
          edgePadding: Self.routeViewportEdgeInsets,
          animated: false
        )
      }
    }
  }

  func aMapSearchRequest(_: Any!, didFailWithError _: Error!) {
    // Step 1. 不自动重试，避免产生多次计费
  }

  private func parsePolyline(_ polyline: String?) -> [CLLocationCoordinate2D] {
    // Step 1. 空值处理
    guard let polyline, !polyline.isEmpty else { return [] }

    // Step 2. 解析 "lon,lat;lon,lat" 格式
    let pairs = polyline.split(separator: ";")
    var result: [CLLocationCoordinate2D] = []
    result.reserveCapacity(pairs.count)
    for pair in pairs {
      let parts = pair.split(separator: ",")
      if parts.count != 2 { continue }
      guard let lon = Double(parts[0]), let lat = Double(parts[1]) else { continue }
      result.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
    }
    return result
  }
}
