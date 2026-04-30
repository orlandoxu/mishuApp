import Foundation

struct PartnerInvitationShareData: Codable {
  let token: String
  let shareUrl: String
  let openAppUrl: String
  let expiresAt: String
  let inviterName: String
  let inviterAvatarUrl: String
  let shareTitle: String
  let shareDescription: String
}

struct PartnerRelationshipData: Codable {
  let hasPartner: Bool
  let partnerUserId: String?
  let inviterUserId: String?
  let invitationToken: String?
  let createdAt: String?
}

final class PartnerAPI {
  static let shared = PartnerAPI()

  private let client: APIClient

  private init(client: APIClient = APIClient()) {
    self.client = client
  }

  func createInvitation(inviterName: String, inviterAvatarUrl: String) async -> PartnerInvitationShareData? {
    await client.postRequest(
      "/partner/invitations",
      AnyParams([
        "inviterName": inviterName,
        "inviterAvatarUrl": inviterAvatarUrl,
      ]),
      true,
      true
    )
  }

  func relationship() async -> PartnerRelationshipData? {
    await client.getRequest("/partner/relationship", Empty(), true, true)
  }
}
