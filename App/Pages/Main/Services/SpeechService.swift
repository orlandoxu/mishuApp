import Compression
import Foundation

final class VolcSpeechService: ObservableObject {
  private var webSocketTask: URLSessionWebSocketTask?
  private var urlSession: URLSession?
  private var startPacketTask: DispatchWorkItem?

  @Published private(set) var isConnected: Bool = false
  @Published private(set) var isRecording: Bool = false
  @Published private(set) var connectionError: String = ""

  var onUtterancesRecognized: (([AsrUtterance]) -> Void)?
  var onConnState: ((Bool) -> Void)?
  var onRecordingStarted: (() -> Void)?
  var onRecordingStopped: ((SpeechStopReason) -> Void)?

  private var sequenceNumber: UInt32 = 0
  private let resourceId = AppConst.volcSpeechResourceID
  private let serverUrl = AppConst.volcSpeechServerURL

  private var apiKey: String = ""
  private var appID: String = ""
  private var connectionCompletion: ((Bool) -> Void)?

  init() {
    let configuration = URLSessionConfiguration.default
    configuration.timeoutIntervalForRequest = 30
    configuration.timeoutIntervalForResource = 60
    urlSession = URLSession(configuration: configuration)
  }

  func startRecording(completion: @escaping (Bool) -> Void) {
    apiKey = AppConst.volcSpeechAccessKey
    appID = AppConst.volcSpeechAppID

    sequenceNumber = 0
    connectionError = ""

    connectionCompletion = completion
    connect()
  }

  func stopRecording() {
    if isRecording {
      sendEndPacket()
    }

    isRecording = false
    disconnect(reason: .userStopped)
  }

  func sendAudio(_ data: Data) {
    guard isConnected, isRecording else { return }
    sequenceNumber += 1
    sendRawAudioData(data, messageFlagBits: 0x00)
  }

  private func connect() {
    let urlString = "\(serverUrl)?api_key=\(apiKey)&api_resource_id=\(resourceId)"

    guard let url = URL(string: urlString) else {
      connectionError = "无效的语音服务地址"
      connectionCompletion?(false)
      connectionCompletion = nil
      return
    }

    var request = URLRequest(url: url)
    request.setValue(appID, forHTTPHeaderField: "X-Api-App-Key")
    request.setValue(apiKey, forHTTPHeaderField: "X-Api-Access-Key")
    request.setValue(resourceId, forHTTPHeaderField: "X-Api-Resource-Id")
    request.setValue(UUID().uuidString, forHTTPHeaderField: "X-Api-Connect-Id")

    webSocketTask = urlSession?.webSocketTask(with: request)
    webSocketTask?.resume()

    receiveMessage()

    startPacketTask?.cancel()
    let work = DispatchWorkItem { [weak self] in
      guard let self, self.webSocketTask != nil else { return }
      self.sendStartPacket()
    }
    startPacketTask = work
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: work)
  }

  private func disconnect(reason: SpeechStopReason) {
    startPacketTask?.cancel()
    startPacketTask = nil

    webSocketTask?.cancel(with: .goingAway, reason: nil)
    webSocketTask = nil

    let wasConnected = isConnected
    isConnected = false
    isRecording = false

    onConnState?(false)

    if wasConnected {
      onRecordingStopped?(reason)
    }
  }

  private func sendStartPacket() {
    let requestData: [String: Any] = [
      "app": [
        "appid": appID,
        "token": apiKey,
        "cluster": resourceId,
      ],
      "user": ["uid": UUID().uuidString],
      "audio": [
        "format": "pcm",
        "rate": 16000,
        "bits": 16,
        "channel": 1,
        "codec": "raw",
      ],
      "request": [
        "reqid": UUID().uuidString,
        "sequence": 1,
        "model_name": "bigmodel",
        "result_type": "single",
        "show_utterances": true,
        "vad": [
          "server_vad": true,
          "speech_noise": true,
        ],
        "language_hints": ["zh", "en"],
        "sequence_number": 1,
        "sequence_timeout_ms": 1000,
        "boosted_keywords": [],
        "filter_garbage_chars": false,
        "disable_punctuation": false,
      ],
    ]

    sendWebSocketMessage(requestData, messageType: .clientRequest)
  }

  private func sendEndPacket() {
    sequenceNumber += 1
    sendRawAudioData(Data(), messageFlagBits: 0x02)
  }

  private func sendRawAudioData(_ data: Data, messageFlagBits: UInt8) {
    let message = makeMessage(
      payload: data,
      messageType: 0x02,
      messageFlagBits: messageFlagBits,
      serialization: 0
    )
    sendMessageData(message)
  }

  private enum MessageType {
    case clientRequest
  }

  private func sendWebSocketMessage(_ data: [String: Any], messageType: MessageType) {
    guard let jsonData = try? JSONSerialization.data(withJSONObject: data) else { return }
    sendRawMessage(data: jsonData, messageType: messageType)
  }

  private func sendRawMessage(data: Data, messageType: MessageType) {
    let message = makeMessage(
      payload: data,
      messageType: messageTypeNibble(for: messageType),
      messageFlagBits: 0,
      serialization: 0x01
    )
    sendMessageData(message)
  }

  private func makeMessage(payload: Data, messageType: UInt8, messageFlagBits: UInt8, serialization: UInt8) -> Data {
    let header: UInt8 = (0x01 << 4) | (0x01 << 0)
    let messageFlags: UInt8 = (messageType << 4) | (messageFlagBits & 0x0F)
    let serializationFlags: UInt8 = serialization << 4

    var message = Data([header, messageFlags, serializationFlags, 0x00])
    message.appendUInt32(UInt32(payload.count))
    message.append(payload)
    return message
  }

  private func sendMessageData(_ message: Data) {
    webSocketTask?.send(.data(message)) { [weak self] error in
      if error != nil {
        self?.handleDisconnected()
      }
    }
  }

  private func messageTypeNibble(for type: MessageType) -> UInt8 {
    switch type {
    case .clientRequest:
      return 0x01
    }
  }

  private func decompressGzip(_ data: Data) -> Data? {
    guard !data.isEmpty else { return nil }

    let bufferSize = data.count * 10
    var destinationBuffer = [UInt8](repeating: 0, count: bufferSize)

    let decompressedSize = compression_decode_buffer(
      &destinationBuffer,
      bufferSize,
      [UInt8](data),
      data.count,
      nil,
      COMPRESSION_ZLIB
    )

    if decompressedSize > 0 {
      return Data(destinationBuffer.prefix(decompressedSize))
    }

    return nil
  }

  private func receiveMessage() {
    webSocketTask?.receive { [weak self] result in
      switch result {
      case let .success(message):
        switch message {
        case let .string(text):
          if let data = Data(base64Encoded: text) {
            self?.handleReceivedData(data)
          }
        case let .data(data):
          self?.handleReceivedData(data)
        @unknown default:
          break
        }

        self?.receiveMessage()

      case .failure:
        self?.handleDisconnected()
      }
    }
  }

  private func handleReceivedData(_ data: Data) {
    guard data.count >= 8 else { return }

    let messageFlags = data[1]
    let serializationFlags = data[2]

    let serialization = (serializationFlags >> 4) & 0x0F
    let compression = serializationFlags & 0x0F

    let flags = messageFlags & 0x0F
    let payloadOffset: Int
    let payloadSize: Int

    if flags == 1 {
      guard data.count >= 12 else { return }
      payloadSize = (Int(data[8]) << 24) | (Int(data[9]) << 16) | (Int(data[10]) << 8) | Int(data[11])
      payloadOffset = 12
    } else {
      payloadSize = (Int(data[4]) << 24) | (Int(data[5]) << 16) | (Int(data[6]) << 8) | Int(data[7])
      payloadOffset = 8
    }

    guard data.count >= payloadOffset + payloadSize else { return }

    let payload = data.subdata(in: payloadOffset ..< (payloadOffset + payloadSize))
    var jsonData = payload
    if compression == 1 {
      jsonData = decompressGzip(payload) ?? payload
    }

    if serialization == 1,
       let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
    {
      processRecognitionResult(json)
    }
  }

  private func processRecognitionResult(_ json: [String: Any]) {
    if let message = (json["error"] as? [String: Any])?["message"] as? String {
      connectionError = message
      handleDisconnected()
      return
    }

    if json["result"] != nil, !isConnected {
      isConnected = true
      isRecording = true
      onConnState?(true)
      finishConnection(success: true)
      onRecordingStarted?()
    }

    guard let result = json["result"] as? [String: Any] else { return }
    let utterances = parseUtterances(from: result)
    guard !utterances.isEmpty else { return }

    DispatchQueue.main.async { [weak self] in
      self?.onUtterancesRecognized?(utterances)
    }
  }

  private func parseUtterances(from result: [String: Any]) -> [AsrUtterance] {
    guard let rawUtterances = result["utterances"] as? [[String: Any]] else {
      return []
    }

    return rawUtterances.compactMap { item in
      guard let text = item["text"] as? String, !text.isEmpty else {
        return nil
      }

      let definite = parseDefinite(item["definite"])
      let startMs = item["start_time"] as? Int ?? item["start_ms"] as? Int
      let endMs = item["end_time"] as? Int ?? item["end_ms"] as? Int
      return AsrUtterance(text: text, definite: definite, startMs: startMs, endMs: endMs)
    }
  }

  private func parseDefinite(_ raw: Any?) -> Bool {
    switch raw {
    case let value as Bool:
      return value
    case let value as Int:
      return value != 0
    case let value as NSNumber:
      return value.boolValue
    case let value as String:
      return value.lowercased() == "true" || value == "1"
    default:
      return false
    }
  }

  private func handleDisconnected() {
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }

      let wasRecording = self.isRecording

      self.isConnected = false
      self.isRecording = false
      self.onConnState?(false)

      self.finishConnection(success: false)

      if wasRecording {
        self.onRecordingStopped?(.disconnected)
      }

      self.webSocketTask?.cancel(with: .goingAway, reason: nil)
      self.webSocketTask = nil
    }
  }

  private func finishConnection(success: Bool) {
    guard let completion = connectionCompletion else { return }
    completion(success)
    connectionCompletion = nil
  }
}

private extension Data {
  mutating func appendUInt32(_ value: UInt32) {
    append(contentsOf: [
      UInt8((value >> 24) & 0xFF),
      UInt8((value >> 16) & 0xFF),
      UInt8((value >> 8) & 0xFF),
      UInt8(value & 0xFF),
    ])
  }
}
