import Foundation
import UIKit

final class UploadAPI {
  static let shared = UploadAPI()

  private let client: APIClient
  private let session: URLSession

  init(client: APIClient = APIClient(), session: URLSession = .shared) {
    self.client = client
    self.session = session
  }

  struct QiniuTokenPayload: Encodable {
    let ext: String
    let type: String
  }

  struct QiniuToken: Decodable {
    let token: String
    let uploadUrl: String
    let cdnUrl: String
    let key: String
  }

  // TODO: 这个不对，应该调用ResourceApi里面的
  // func getAvatarToken(ext: String) async throws -> QiniuToken {
  //   try await client.request(
  //     .Post,
  //     "/api/upload/qiniu-token",
  //     QiniuTokenPayload(ext: ext, type: "avatar")
  //   )
  // }

  @discardableResult
  func uploadImage2QiNiu(data: Data, mime: String, token: UploadTokenData) async -> String? {
    await uploadData2QiNiu(
      data: data,
      mime: mime,
      fileName: token.url,
      token: token
    )
  }

  @discardableResult
  func uploadData2QiNiu(
    data: Data,
    mime: String,
    fileName: String,
    token: UploadTokenData
  ) async -> String? {
    // 目前只有这儿用到
    struct QiniuUploadResponse: Decodable {
      let key: String
      let hash: String
    }

    guard let url = URL(string: token.endPoint) else { return nil }

    let boundary = "Boundary-\(UUID().uuidString)"
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

    var body = Data()
    body.appendMultipartField(name: "token", value: token.token, boundary: boundary)
    body.appendMultipartField(name: "key", value: token.url, boundary: boundary)
    body.appendMultipartFile(
      name: "file",
      fileName: fileName,
      mime: mime,
      data: data,
      boundary: boundary
    )
    body.appendString("--\(boundary)--\r\n")

    let respData: Data
    let resp: URLResponse
    do {
      (respData, resp) = try await session.upload(for: request, from: body)
    } catch {
      return nil
    }

    guard let http = resp as? HTTPURLResponse else { return nil }

    if !(200 ..< 300).contains(http.statusCode) {
      print("上传失败，状态码不是 200 到 299")
      return nil
    }

    if let qiniuResp = try? JSONDecoder().decode(QiniuUploadResponse.self, from: respData) {
      return qiniuResp.key
    }
    return nil
  }
}

private extension Data {
  mutating func appendString(_ v: String) {
    if let d = v.data(using: .utf8) {
      append(d)
    }
  }

  mutating func appendMultipartField(name: String, value: String, boundary: String) {
    appendString("--\(boundary)\r\n")
    appendString("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
    appendString(value)
    appendString("\r\n")
  }

  mutating func appendMultipartFile(
    name: String,
    fileName: String,
    mime: String,
    data: Data,
    boundary: String
  ) {
    appendString("--\(boundary)\r\n")
    appendString("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n")
    appendString("Content-Type: \(mime)\r\n\r\n")
    append(data)
    appendString("\r\n")
  }
}
