import Foundation

final class DoubaoEmbeddingAPI {
  static let shared = DoubaoEmbeddingAPI()

  private let session: URLSession

  init(session: URLSession = .shared) {
    self.session = session
  }

  func embed(text: String, model: String = AppConst.doubaoEmbeddingModel, dimensions: Int = AppConst.doubaoEmbeddingDimension) async -> [Double]? {
    let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !cleaned.isEmpty else { return nil }

    let apiKey = AppConst.doubaoEmbeddingApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !apiKey.isEmpty else {
      LKLog("doubao embedding skipped: missing api key", type: "memory", label: "warning")
      return nil
    }

    let rawBase = AppConst.doubaoEmbeddingBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !rawBase.isEmpty else {
      LKLog("doubao embedding skipped: missing base url", type: "memory", label: "warning")
      return nil
    }

    let urlText = rawBase.hasSuffix("/") ? "\(rawBase)embeddings" : "\(rawBase)/embeddings"
    guard let url = URL(string: urlText) else {
      LKLog("doubao embedding skipped: invalid base url \(urlText)", type: "memory", label: "error")
      return nil
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.timeoutInterval = 20
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

    let payload = DoubaoEmbeddingRequest(
      model: model,
      input: cleaned,
      encodingFormat: "float",
      dimensions: dimensions
    )

    do {
      request.httpBody = try JSONEncoder().encode(payload)
      let (data, response) = try await session.data(for: request)

      guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
        let code = (response as? HTTPURLResponse)?.statusCode ?? -1
        LKLog("doubao embedding failed: http \(code)", type: "memory", label: "error")
        return nil
      }

      let parsed = try JSONDecoder().decode(DoubaoEmbeddingResponse.self, from: data)
      guard let vector = parsed.data.first?.embedding, !vector.isEmpty else {
        LKLog("doubao embedding failed: empty vector", type: "memory", label: "error")
        return nil
      }
      return vector
    } catch {
      LKLog("doubao embedding failed: \(error.localizedDescription)", type: "memory", label: "error")
      return nil
    }
  }
}

private struct DoubaoEmbeddingRequest: Encodable {
  let model: String
  let input: String
  let encodingFormat: String
  let dimensions: Int

  private enum CodingKeys: String, CodingKey {
    case model
    case input
    case encodingFormat = "encoding_format"
    case dimensions
  }
}

private struct DoubaoEmbeddingResponse: Decodable {
  let data: [DoubaoEmbeddingItem]
}

private struct DoubaoEmbeddingItem: Decodable {
  let embedding: [Double]
}
