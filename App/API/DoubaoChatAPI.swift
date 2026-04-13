import Foundation

final class DoubaoChatAPI {
  static let shared = DoubaoChatAPI()

  private let session: URLSession

  init(session: URLSession = .shared) {
    self.session = session
  }

  func chat(
    systemPrompt: String,
    userPrompt: String,
    temperature: Double = 0.2
  ) async -> String? {
    let apiKey = AppConst.doubaoEmbeddingApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !apiKey.isEmpty else {
      LKLog("doubao chat skipped: missing api key", type: "memory", label: "warning")
      return nil
    }

    let rawBase = AppConst.doubaoChatBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !rawBase.isEmpty else {
      LKLog("doubao chat skipped: missing base url", type: "memory", label: "warning")
      return nil
    }

    let urlText = rawBase.hasSuffix("/") ? "\(rawBase)chat/completions" : "\(rawBase)/chat/completions"
    guard let url = URL(string: urlText) else {
      LKLog("doubao chat skipped: invalid base url \(urlText)", type: "memory", label: "error")
      return nil
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.timeoutInterval = 30
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

    let payload = DoubaoChatRequest(
      model: AppConst.doubaoChatModel,
      messages: [
        .init(role: "system", content: systemPrompt),
        .init(role: "user", content: userPrompt),
      ],
      temperature: temperature
    )

    do {
      request.httpBody = try JSONEncoder().encode(payload)
      let (data, response) = try await session.data(for: request)
      guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
        let code = (response as? HTTPURLResponse)?.statusCode ?? -1
        LKLog("doubao chat failed: http \(code)", type: "memory", label: "error")
        return nil
      }

      let parsed = try JSONDecoder().decode(DoubaoChatResponse.self, from: data)
      return parsed.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
    } catch {
      LKLog("doubao chat failed: \(error.localizedDescription)", type: "memory", label: "error")
      return nil
    }
  }
}

private struct DoubaoChatRequest: Encodable {
  let model: String
  let messages: [DoubaoChatMessage]
  let temperature: Double
}

private struct DoubaoChatMessage: Codable {
  let role: String
  let content: String
}

private struct DoubaoChatResponse: Decodable {
  let choices: [DoubaoChatChoice]
}

private struct DoubaoChatChoice: Decodable {
  let message: DoubaoChatMessage
}
