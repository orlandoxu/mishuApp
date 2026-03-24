import Foundation

// DONE-AI: 已包含 geocode 相关接口
final class GeocodeAPI {
  static let shared = GeocodeAPI()

  let client: APIClient

  private init(client: APIClient = APIClient()) {
    self.client = client
  }

  func regeoServer(payload: Empty = Empty()) async -> GeocodeRegeoServerData? {
    // Step 1. 组装服务端逆地理请求参数
    // Step 2. 发起服务端逆地理请求
    return await client.postRequest(
      "/v4/s/geocode/regeo", payload, true, true
    )
  }

  func limitGeo(payload: Empty = Empty()) async -> GeocodeLimitGeoData? {
    // Step 1. 组装定位限制请求参数
    // Step 2. 发起定位限制请求
    return await client.postRequest(
      "/v4/u/geocode/limitGeo", payload, true, false
    )
  }

  func regeo(payload: Empty = Empty()) async -> GeocodeRegeoData? {
    // Step 1. 组装逆地理请求参数
    // Step 2. 发起逆地理请求
    return await client.postRequest(
      "/v4/u/geocode/regeo", payload, true, false
    )
  }

  func resGeGeo(payload: Empty = Empty()) async -> GeocodeResGeGeoData? {
    // Step 1. 组装资源逆地理请求参数
    // Step 2. 发起资源逆地理请求
    return await client.postRequest(
      "/v4/u/resGeGeo", payload, true, false
    )
  }

  func travelReGeo(payload: Empty = Empty()) async -> GeocodeTravelReGeoData? {
    // Step 1. 组装行程逆地理请求参数
    // Step 2. 发起行程逆地理请求
    return await client.postRequest(
      "/v4/u/travelReGeo", payload, true, false
    )
  }
}

struct GeocodeRegeoServerData: Decodable {}
struct GeocodeLimitGeoData: Decodable {}
struct GeocodeRegeoData: Decodable {}
struct GeocodeResGeGeoData: Decodable {}
struct GeocodeTravelReGeoData: Decodable {}
