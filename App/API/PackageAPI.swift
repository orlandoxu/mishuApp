import Foundation

// DONE-AI: 已改为强类型返回
final class PackageAPI {
  static let shared = PackageAPI()

  let client: APIClient

  private init(client: APIClient = APIClient()) {
    self.client = client
  }

  // func canMigrate(payload: Empty = Empty()) async -> PackageCanMigrateData? {
  //   return await client.postRequest(
  //     "/v4/u/package/canMigrate", payload, true, false
  //   )
  // }

  func getInitPackageInfo(payload: Empty = Empty()) async -> PackageInitInfoData? {
    return await client.postRequest(
      "/v4/u/package/getInitPackageInfo", payload
    )
  }

  func getPackages(_ imei: String, type: String = "init") async -> [PackageItem]? {
    return await client.postRequest(
      "/v4/u/package/getPackages", AnyParams(["imei": imei, "type": type, "method": "APP"]), true, true
    )
  }

  func order(payload: Empty = Empty()) async -> PackageOrderData? {
    return await client.postRequest(
      "/v4/u/package/order", payload, true, true
    )
  }

  func receivePackage(payload: Empty = Empty()) async -> PackageReceiveData? {
    return await client.postRequest(
      "/v4/u/package/receivePackage", payload, true, true
    )
  }

  func userInfo(payload: Empty = Empty()) async -> PackageUserInfoData? {
    return await client.postRequest(
      "/v4/u/package/userInfo", payload, true, false
    )
  }

  func userUsing(payload: Empty = Empty()) async -> PackageUserUsingData? {
    return await client.postRequest(
      "/v4/u/package/userUsing", payload, true, false
    )
  }
}

// DONE-AI: Package相关模型已迁移到Models/PackageModels.swift
