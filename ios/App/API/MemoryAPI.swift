import Foundation

final class MemoryAPI {
  static let shared = MemoryAPI()

  private let client: APIClient

  init(client: APIClient = APIClient()) {
    self.client = client
  }

  func ingest(payload: MemoryIngestPayload) async -> Bool {
    let endpoint = AppConst.memoryIngestEndpoint
    let result: Empty? = await client.postRequest(endpoint, payload, true, false)
    return result != nil
  }
}

struct MemoryIngestPayload: Encodable {
  let userId: String
  let text: String
  let embedding: [Double]
  let embeddingModel: String
  let embeddingDimension: Int
  let source: String
  let createdAtMs: Int64
}
