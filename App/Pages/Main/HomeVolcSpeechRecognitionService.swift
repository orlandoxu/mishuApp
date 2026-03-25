import Compression
import Foundation

final class HomeVolcSpeechRecognitionService: ObservableObject {
  private var webSocketTask: URLSessionWebSocketTask?
  private var urlSession: URLSession?
  private var startPacketWorkItem: DispatchWorkItem?

  @Published private(set) var isConnected: Bool = false
  @Published private(set) var isRecording: Bool = false
  @Published private(set) var connectionError: String = ""

  var onUtterancesRecognized: (([HomeASRUtterance]) -> Void)?
  var onConnectionStateChanged: ((Bool) -> Void)?
  var onRecordingStarted: (() -> Void)?
  var onRecordingStopped: ((HomeSpeechStopReason) -> Void)?

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
    sendRawAudioData(data, messageFlagBits: 0x00, sequence: sequenceNumber)
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

    startPacketWorkItem?.cancel()
    let work = DispatchWorkItem { [weak self] in
      guard let self, self.webSocketTask != nil else { return }
      self.sendStartPacket()
    }
    startPacketWorkItem = work
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: work)
  }

  private func disconnect(reason: HomeSpeechStopReason) {
    startPacketWorkItem?.cancel()
    startPacketWorkItem = nil

    webSocketTask?.cancel(with: .goingAway, reason: nil)
    webSocketTask = nil

    let wasConnected = isConnected
    isConnected = false
    isRecording = false

    onConnectionStateChanged?(false)

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
    sendRawAudioData(Data(), messageFlagBits: 0x02, sequence: sequenceNumber)
  }

  private func sendRawAudioData(_ data: Data, messageFlagBits: UInt8, sequence _: UInt32) {
    var header: UInt8 = 0
    header |= 0x01 << 4
    header |= 0x01 << 0

    var messageFlags: UInt8 = 0
    messageFlags |= 0x02 << 4
    messageFlags |= messageFlagBits & 0x0F

    let serializationFlags: UInt8 = 0

    var message = Data([header, messageFlags, serializationFlags, 0x00])

    let audioSize = UInt32(data.count)
    message.append(contentsOf: [
      UInt8((audioSize >> 24) & 0xFF),
      UInt8((audioSize >> 16) & 0xFF),
      UInt8((audioSize >> 8) & 0xFF),
      UInt8(audioSize & 0xFF),
    ])

    message.append(data)

    webSocketTask?.send(.data(message)) { [weak self] error in
      if error != nil {
        self?.handleDisconnected()
      }
    }
  }

  private enum MessageType {
    case clientRequest
  }

  private func sendWebSocketMessage(_ data: [String: Any], messageType: MessageType) {
    guard let jsonData = try? JSONSerialization.data(withJSONObject: data) else { return }
    sendRawMessage(data: jsonData, messageType: messageType)
  }

  private func sendRawMessage(data: Data, messageType: MessageType) {
    var header: UInt8 = 0
    header |= 0x01 << 4
    header |= 0x01 << 0

    var messageFlags: UInt8 = 0
    switch messageType {
    case .clientRequest:
      messageFlags |= 0x01 << 4
    }

    var serializationFlags: UInt8 = 0
    serializationFlags |= 0x01 << 4

    var message = Data([header, messageFlags, serializationFlags, 0x00])

    let size = UInt32(data.count)
    message.append(contentsOf: [
      UInt8((size >> 24) & 0xFF),
      UInt8((size >> 16) & 0xFF),
      UInt8((size >> 8) & 0xFF),
      UInt8(size & 0xFF),
    ])

    message.append(data)

    webSocketTask?.send(.data(message)) { [weak self] error in
      if error != nil {
        self?.handleDisconnected()
      }
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
    if let error = json["error"] as? [String: Any] {
      if let message = error["message"] as? String {
        connectionError = message
      }
      handleDisconnected()
      return
    }

    if json["result"] != nil, !isConnected {
      isConnected = true
      isRecording = true
      onConnectionStateChanged?(true)

      if connectionCompletion != nil {
        connectionCompletion?(true)
        connectionCompletion = nil
      }

      onRecordingStarted?()
    }

    guard let result = json["result"] as? [String: Any] else { return }
    let utterances = parseUtterances(from: result)
    guard !utterances.isEmpty else { return }

    DispatchQueue.main.async { [weak self] in
      self?.onUtterancesRecognized?(utterances)
    }
  }

  private func parseUtterances(from result: [String: Any]) -> [HomeASRUtterance] {
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
      return HomeASRUtterance(text: text, definite: definite, startMs: startMs, endMs: endMs)
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
      self.onConnectionStateChanged?(false)

      if self.connectionCompletion != nil {
        self.connectionCompletion?(false)
        self.connectionCompletion = nil
      }

      if wasRecording {
        self.onRecordingStopped?(.disconnected)
      }

      self.webSocketTask?.cancel(with: .goingAway, reason: nil)
      self.webSocketTask = nil
    }
  }
}
