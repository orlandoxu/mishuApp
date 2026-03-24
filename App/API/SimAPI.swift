import Foundation

final class SimAPI {
  static let shared = SimAPI()

  let client: APIClient

  private init(client: APIClient = APIClient()) {
    self.client = client
  }

  func getSimCard(payload: Empty = Empty()) async -> SimModel? {
    return await client.postRequest(
      "/v4/u/sim/getSimCard", payload, true, false
    )
  }
}
