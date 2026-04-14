import AVFoundation
import Foundation
import Speech

@available(iOS 26.0, *)
final class SpeechAnalyzerService: ObservableObject, SpeechRecognitionService {
  @Published private(set) var isConnected: Bool = false
  @Published private(set) var isRecording: Bool = false
  @Published private(set) var connectionError: String = ""

  var onUtterancesRecognized: (([AsrUtterance]) -> Void)?
  var onConnState: ((Bool) -> Void)?
  var onRecordingStarted: (() -> Void)?
  var onRecordingStopped: ((SpeechStopReason) -> Void)?

  private var analyzer: SpeechAnalyzer?
  private var transcriber: SpeechTranscriber?
  private var inputContinuation: AsyncThrowingStream<AnalyzerInput, Error>.Continuation?

  private var analysisTask: Task<Void, Never>?
  private var resultTask: Task<Void, Never>?
  private var connectionCompletion: ((Bool) -> Void)?
  private var reservedLocale: Locale?
  private var hasStartedSession = false
  private var isStarting = false

  private let recognitionLocale = Locale(identifier: "zh-CN")

  private lazy var inputFormat: AVAudioFormat? = {
    AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 16000, channels: 1, interleaved: true)
  }()

  func startRecording(completion: @escaping (Bool) -> Void) {
    guard !isStarting, analysisTask == nil, resultTask == nil else {
      connectionError = "语音识别正在启动，请稍后重试"
      completion(false)
      return
    }

    connectionError = ""
    teardownSessionCallbacks()
    isStarting = true

    guard SpeechTranscriber.isAvailable else {
      connectionError = "SpeechAnalyzer 当前不可用"
      isStarting = false
      completion(false)
      return
    }

    guard let inputFormat else {
      connectionError = "无法初始化音频格式"
      isStarting = false
      completion(false)
      return
    }

    connectionCompletion = completion
    analysisTask = Task { [weak self] in
      guard let self else { return }
      do {
        let locale = await SpeechTranscriber.supportedLocale(equivalentTo: self.recognitionLocale) ?? self.recognitionLocale
        let transcriber = SpeechTranscriber(locale: locale, preset: .timeIndexedProgressiveTranscription)
        self.transcriber = transcriber

        try await self.prepareAssetsIfNeeded(for: transcriber, locale: locale)

        let stream = AsyncThrowingStream<AnalyzerInput, Error> { [weak self] continuation in
          self?.inputContinuation = continuation
        }

        let analyzer = SpeechAnalyzer(modules: [transcriber])
        self.analyzer = analyzer

        self.resultTask = Task { [weak self] in
          await self?.consumeTranscriberResults(transcriber)
        }

        try await analyzer.prepareToAnalyze(in: inputFormat)
        await MainActor.run {
          self.markConnectedIfNeeded()
        }
        try await analyzer.start(inputSequence: stream)
      } catch {
        if error is CancellationError {
          return
        }
        await MainActor.run {
          self.connectionError = self.connectionError.isEmpty ? "SpeechAnalyzer 识别失败" : self.connectionError
          self.handleDisconnected(reason: .disconnected)
        }
      }
    }
  }

  func stopRecording() {
    guard isRecording || isConnected else { return }
    let analyzer = self.analyzer

    inputContinuation?.finish()
    inputContinuation = nil

    isRecording = false
    disconnect(reason: .userStopped)

    Task {
      guard let analyzer else { return }
      try? await analyzer.finalizeAndFinishThroughEndOfInput()
    }
  }

  func sendAudio(_ data: Data) {
    guard isConnected, isRecording else { return }
    guard let buffer = makePCMBuffer(from: data) else { return }
    inputContinuation?.yield(AnalyzerInput(buffer: buffer))
  }

  private func consumeTranscriberResults(_ transcriber: SpeechTranscriber) async {
    do {
      for try await result in transcriber.results {
        let plainText = String(result.text.characters).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !plainText.isEmpty else { continue }

        let startMs = toMilliseconds(result.range.start)
        let endMs = toMilliseconds(result.range.end)
        let utterance = AsrUtterance(text: plainText, definite: result.isFinal, startMs: startMs, endMs: endMs)

        await MainActor.run {
          self.onUtterancesRecognized?([utterance])
        }
      }
    } catch {
      if error is CancellationError {
        return
      }
      await MainActor.run {
        self.connectionError = self.connectionError.isEmpty ? "SpeechAnalyzer 结果流中断" : self.connectionError
        self.handleDisconnected(reason: .disconnected)
      }
    }
  }

  private func makePCMBuffer(from data: Data) -> AVAudioPCMBuffer? {
    guard let inputFormat else { return nil }

    let sampleCount = data.count / MemoryLayout<Int16>.size
    guard sampleCount > 0,
          let pcmBuffer = AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: AVAudioFrameCount(sampleCount))
    else {
      return nil
    }

    pcmBuffer.frameLength = AVAudioFrameCount(sampleCount)

    guard let channels = pcmBuffer.int16ChannelData else {
      return nil
    }

    _ = data.copyBytes(to: UnsafeMutableBufferPointer(start: channels[0], count: sampleCount))
    return pcmBuffer
  }

  private func toMilliseconds(_ time: CMTime) -> Int? {
    guard time.isValid else { return nil }
    let seconds = CMTimeGetSeconds(time)
    guard seconds.isFinite else { return nil }
    return Int(seconds * 1000.0)
  }

  private func markConnectedIfNeeded() {
    guard !hasStartedSession else { return }

    hasStartedSession = true
    isStarting = false
    isConnected = true
    isRecording = true
    onConnState?(true)
    finishConnection(success: true)
    onRecordingStarted?()
  }

  private func finishConnection(success: Bool) {
    guard let completion = connectionCompletion else { return }
    completion(success)
    connectionCompletion = nil
  }

  private func handleDisconnected(reason: SpeechStopReason) {
    let wasConnected = isConnected
    isConnected = false
    isRecording = false

    if wasConnected {
      onConnState?(false)
      onRecordingStopped?(reason)
    }

    finishConnection(success: false)
    teardownSessionCallbacks()
  }

  private func disconnect(reason: SpeechStopReason) {
    let wasConnected = isConnected

    isConnected = false
    isRecording = false

    if wasConnected {
      onConnState?(false)
      onRecordingStopped?(reason)
    }

    teardownSessionCallbacks()
  }

  private func teardownSessionCallbacks() {
    analysisTask?.cancel()
    resultTask?.cancel()

    if let reservedLocale {
      Task {
        _ = await AssetInventory.release(reservedLocale: reservedLocale)
      }
    }

    analysisTask = nil
    resultTask = nil
    analyzer = nil
    transcriber = nil
    inputContinuation = nil
    reservedLocale = nil
    hasStartedSession = false
    isStarting = false
    connectionCompletion = nil
  }

  private func prepareAssetsIfNeeded(for transcriber: SpeechTranscriber, locale: Locale) async throws {
    if reservedLocale != locale {
      _ = try await AssetInventory.reserve(locale: locale)
      reservedLocale = locale
    }

    var status = await AssetInventory.status(forModules: [transcriber])
    if status != .installed {
      if let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
        try await request.downloadAndInstall()
      }
      status = await AssetInventory.status(forModules: [transcriber])
    }

    guard status == .installed else {
      throw NSError(domain: "SpeechAnalyzerService", code: -1, userInfo: [
        NSLocalizedDescriptionKey: "SpeechAnalyzer 语音资源未就绪"
      ])
    }
  }
}
