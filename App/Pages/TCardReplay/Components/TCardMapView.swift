import MapKit
import SwiftUI

struct TCardMapView: View {
  @EnvironmentObject private var viewModel: TCardReplayViewModel

  @State private var region = MKCoordinateRegion(
    center: CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074), // Beijing
    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
  )

  var body: some View {
    let replayPoint = viewModel.tCardReplayMapPoint
    let carCoordinate = replayPoint.map {
      CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
    }
    let carDirection = replayPoint?.direction ?? 0

    // 如果有回放轨迹点，地图自动跟随该点。
    let center = carCoordinate ?? region.center

    let binding = Binding(
      get: {
        MKCoordinateRegion(center: center, span: region.span)
      },
      set: { region = $0 }
    )

    return Map(coordinateRegion: binding)
      .overlay(
        Group {
          if carCoordinate != nil {
            Image("icon_map_car")
              .resizable()
              .scaledToFit()
              .frame(width: 32, height: 53)
              .rotationEffect(.degrees(carDirection))
              .shadow(radius: 2)
          } else {
            VStack {
              Spacer().frame(height: 30)
              Text("暂无车辆位置信息")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "0x333333"))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.9))
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
              Spacer()
            }
          }
        }
      )
  }
}
