import AMapFoundationKit
import MAMapKit
import SwiftUI
import UIKit

struct AlbumDetailMapView: UIViewRepresentable {
  let poses: [CLLocationCoordinate2D]
  let currentPoseIndex: Int
  let centerCoordinate: CLLocationCoordinate2D?

  init(
    poses: [CLLocationCoordinate2D],
    currentPoseIndex: Int,
    centerCoordinate: CLLocationCoordinate2D? = nil
  ) {
    self.poses = poses
    self.currentPoseIndex = currentPoseIndex
    self.centerCoordinate = centerCoordinate
  }

  func makeUIView(context: Context) -> MAMapView {
    AMapBootstrap.setupIfNeeded()

    let mapView = MAMapView(frame: .zero)
    mapView.delegate = context.coordinator
    mapView.showsCompass = false
    mapView.showsScale = false
    mapView.isRotateEnabled = false
    mapView.isRotateCameraEnabled = false
    mapView.zoomLevel = 16

    if let center = centerCoordinate {
      mapView.setCenter(center, animated: false)
      let annotation = MAPointAnnotation()
      annotation.coordinate = center
      mapView.addAnnotation(annotation)
      context.coordinator.carAnnotation = annotation
    }

    return mapView
  }

  func updateUIView(_ uiView: MAMapView, context: Context) {
    if poses.isEmpty { return }

    if context.coordinator.polyline == nil {
      var coordinates = poses
      let polyline = MAPolyline(coordinates: &coordinates, count: UInt(poses.count))
      context.coordinator.polyline = polyline
      if let polyline {
        uiView.add(polyline)
        let rect = polyline.boundingMapRect
        uiView.setVisibleMapRect(
          rect,
          edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50),
          animated: false
        )
      }
    }

    guard currentPoseIndex < poses.count else { return }
    let coordinate = poses[currentPoseIndex]
    if let annotation = context.coordinator.carAnnotation {
      annotation.coordinate = coordinate
    } else {
      let annotation = MAPointAnnotation()
      annotation.coordinate = coordinate
      uiView.addAnnotation(annotation)
      context.coordinator.carAnnotation = annotation
      uiView.setCenter(coordinate, animated: false)
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  class Coordinator: NSObject, MAMapViewDelegate {
    var carAnnotation: MAPointAnnotation?
    var polyline: MAPolyline?

    func mapView(_ mapView: MAMapView!, viewFor annotation: MAAnnotation!) -> MAAnnotationView! {
      if annotation is MAPointAnnotation {
        let reuseIdentifier = "carAnnotation"
        let annotationView =
          (mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) as? Map4LiveCarAnnotationView)
            ?? Map4LiveCarAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
        annotationView.annotation = annotation
        annotationView.canShowCallout = false
        annotationView.updateHeading(nil)
        annotationView.updateStatus(iconName: nil, description: nil, color: ThemeColor.gray600Ui)
        return annotationView
      }
      return nil
    }

    func mapView(_: MAMapView!, rendererFor overlay: MAOverlay!) -> MAOverlayRenderer! {
      if let polyline = overlay as? MAPolyline {
        let renderer = MAPolylineRenderer(polyline: polyline)
        renderer?.lineWidth = 4
        renderer?.strokeColor = UIColor(red: 0, green: 122 / 255, blue: 1, alpha: 1)
        renderer?.lineJoinType = kMALineJoinRound
        renderer?.lineCapType = kMALineCapRound
        return renderer
      }
      return nil
    }
  }
}

private enum AMapBootstrap {
  private static var didSetup = false

  static func setupIfNeeded() {
    if didSetup { return }
    didSetup = true

    MAMapView.updatePrivacyShow(.didShow, privacyInfo: .didContain)
    MAMapView.updatePrivacyAgree(.didAgree)

    AMapServices.shared().apiKey = AppConst.gaoDeKey
    AMapServices.shared().enableHTTPS = true
  }
}
