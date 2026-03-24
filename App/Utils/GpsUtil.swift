import CoreLocation
import Foundation

enum GpsUtil {
  static let xPi = Double.pi * 3000.0 / 180.0
  static let a = 6_378_245.0
  static let ee = 0.006_693_421_622_965_943_23

  static func outOfChina(lat: Double, lon: Double) -> Bool {
    if lon < 72.004 || lon > 137.8347 { return true }
    if lat < 0.8293 || lat > 55.8271 { return true }
    return false
  }

  static func gps84ToGcj02(_ coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
    gps84ToGcj02(lat: coordinate.latitude, lon: coordinate.longitude)
  }

  static func gps84ToGcj02(lat: Double, lon: Double) -> CLLocationCoordinate2D {
    if outOfChina(lat: lat, lon: lon) {
      return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    var dLat = transformLat(x: lon - 105.0, y: lat - 35.0)
    var dLon = transformLon(x: lon - 105.0, y: lat - 35.0)

    let radLat = lat / 180.0 * Double.pi
    var magic = sin(radLat)
    magic = 1 - ee * magic * magic
    let sqrtMagic = sqrt(magic)

    dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * Double.pi)
    dLon = (dLon * 180.0) / (a / sqrtMagic * cos(radLat) * Double.pi)

    let mgLat = lat + dLat
    let mgLon = lon + dLon
    return CLLocationCoordinate2D(latitude: mgLat, longitude: mgLon)
  }

  static func gcj02ToGps84(_ coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
    gcj02ToGps84(lat: coordinate.latitude, lon: coordinate.longitude)
  }

  static func gcj02ToGps84(lat: Double, lon: Double) -> CLLocationCoordinate2D {
    let gps = transform(lat: lat, lon: lon)
    let lontitude = lon * 2 - gps.longitude
    let latitude = lat * 2 - gps.latitude
    return CLLocationCoordinate2D(latitude: latitude, longitude: lontitude)
  }

  static func gcj02ToBd09(_ coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
    gcj02ToBd09(lat: coordinate.latitude, lon: coordinate.longitude)
  }

  static func gcj02ToBd09(lat: Double, lon: Double) -> CLLocationCoordinate2D {
    let x = lon
    let y = lat
    let z = sqrt(x * x + y * y) + 0.00002 * sin(y * xPi)
    let theta = atan2(y, x) + 0.000003 * cos(x * xPi)
    let tempLon = z * cos(theta) + 0.0065
    let tempLat = z * sin(theta) + 0.006
    return CLLocationCoordinate2D(latitude: tempLat, longitude: tempLon)
  }

  static func bd09ToGcj02(_ coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
    bd09ToGcj02(lat: coordinate.latitude, lon: coordinate.longitude)
  }

  static func bd09ToGcj02(lat: Double, lon: Double) -> CLLocationCoordinate2D {
    let x = lon - 0.0065
    let y = lat - 0.006
    let z = sqrt(x * x + y * y) - 0.00002 * sin(y * xPi)
    let theta = atan2(y, x) - 0.000003 * cos(x * xPi)
    let tempLon = z * cos(theta)
    let tempLat = z * sin(theta)
    return CLLocationCoordinate2D(latitude: tempLat, longitude: tempLon)
  }

  static func gps84ToBd09(_ coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
    gps84ToBd09(lat: coordinate.latitude, lon: coordinate.longitude)
  }

  static func gps84ToBd09(lat: Double, lon: Double) -> CLLocationCoordinate2D {
    let gcj02 = gps84ToGcj02(lat: lat, lon: lon)
    return gcj02ToBd09(gcj02)
  }

  static func bd09ToGps84(_ coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
    bd09ToGps84(lat: coordinate.latitude, lon: coordinate.longitude)
  }

  static func bd09ToGps84(lat: Double, lon: Double) -> CLLocationCoordinate2D {
    let gcj02 = bd09ToGcj02(lat: lat, lon: lon)
    let gps84 = gcj02ToGps84(gcj02)
    return CLLocationCoordinate2D(
      latitude: retain6(gps84.latitude),
      longitude: retain6(gps84.longitude)
    )
  }

  static func bearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
    bearing(lat1: from.latitude, lon1: from.longitude, lat2: to.latitude, lon2: to.longitude)
  }

  static func bearing(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
    let latitude1 = toRadians(lat1)
    let latitude2 = toRadians(lat2)
    let longDiff = toRadians(lon2 - lon1)
    let y = sin(longDiff) * cos(latitude2)
    let x = cos(latitude1) * sin(latitude2) - sin(latitude1) * cos(latitude2) * cos(longDiff)
    return (toDegrees(atan2(y, x)) + 360).truncatingRemainder(dividingBy: 360)
  }

  private static func transform(lat: Double, lon: Double) -> (latitude: Double, longitude: Double) {
    if outOfChina(lat: lat, lon: lon) { return (lat, lon) }

    var dLat = transformLat(x: lon - 105.0, y: lat - 35.0)
    var dLon = transformLon(x: lon - 105.0, y: lat - 35.0)

    let radLat = lat / 180.0 * Double.pi
    var magic = sin(radLat)
    magic = 1 - ee * magic * magic
    let sqrtMagic = sqrt(magic)

    dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * Double.pi)
    dLon = (dLon * 180.0) / (a / sqrtMagic * cos(radLat) * Double.pi)

    let mgLat = lat + dLat
    let mgLon = lon + dLon
    return (mgLat, mgLon)
  }

  private static func transformLat(x: Double, y: Double) -> Double {
    var ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(abs(x))
    ret += (20.0 * sin(6.0 * x * Double.pi) + 20.0 * sin(2.0 * x * Double.pi)) * 2.0 / 3.0
    ret += (20.0 * sin(y * Double.pi) + 40.0 * sin(y / 3.0 * Double.pi)) * 2.0 / 3.0
    ret += (160.0 * sin(y / 12.0 * Double.pi) + 320.0 * sin(y * Double.pi / 30.0)) * 2.0 / 3.0
    return ret
  }

  private static func transformLon(x: Double, y: Double) -> Double {
    var ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(abs(x))
    ret += (20.0 * sin(6.0 * x * Double.pi) + 20.0 * sin(2.0 * x * Double.pi)) * 2.0 / 3.0
    ret += (20.0 * sin(x * Double.pi) + 40.0 * sin(x / 3.0 * Double.pi)) * 2.0 / 3.0
    ret += (150.0 * sin(x / 12.0 * Double.pi) + 300.0 * sin(x / 30.0 * Double.pi)) * 2.0 / 3.0
    return ret
  }

  private static func retain6(_ value: Double) -> Double {
    (value * 1_000_000).rounded() / 1_000_000
  }

  private static func toRadians(_ degrees: Double) -> Double {
    degrees / 180.0 * Double.pi
  }

  private static func toDegrees(_ radians: Double) -> Double {
    radians * 180.0 / Double.pi
  }
}
