import AVFoundation
import Foundation

final class AudioStreamCapture: NSObject, ObservableObject {
  private var audioEngine: AVAudioEngine?
  private var inputNode: AVAudioInputNode?

  var onAudioData: ((Data) -> Void)?
  var onRecordState: ((Bool) -> Void)?

  @Published private(set) var isRecording: Bool = false
  @Published private(set) var audioLevel: CGFloat = 0

  private let sampleRate: Double = 16000
  private let channels: AVAudioChannelCount = 1
  private let audioGain: Float = 2.0
  private let bufferSize: AVAudioFrameCount = 4096
  private var startRetryCount = 0

  func startRecording(completion: @escaping (Bool) -> Void) {
    guard !isRecording else {
      completion(true)
      return
    }

    startRetryCount = 0
    DispatchQueue.main.async {
      self.startAudio(completion: completion)
    }
  }

  func stopRecording() {
    guard isRecording else { return }

    audioEngine?.inputNode.removeTap(onBus: 0)
    audioEngine?.stop()
    audioEngine = nil

    isRecording = false
    audioLevel = 0
    onRecordState?(false)
  }

  private func startAudio(completion: @escaping (Bool) -> Void) {
    audioEngine = AVAudioEngine()
    guard let audioEngine else {
      completion(false)
      return
    }

    inputNode = audioEngine.inputNode
    let inputFormat = inputNode?.inputFormat(forBus: 0)

    guard let format = inputFormat, format.sampleRate > 0, format.channelCount > 0 else {
      completion(false)
      return
    }

    guard
      let desiredFormat = AVAudioFormat(
        commonFormat: .pcmFormatInt16,
        sampleRate: sampleRate,
        channels: channels,
        interleaved: true
      )
    else {
      completion(false)
      return
    }

    guard let converter = AVAudioConverter(from: format, to: desiredFormat) else {
      completion(false)
      return
    }

    inputNode?.installTap(onBus: 0, bufferSize: bufferSize, format: nil) { [weak self] buffer, _ in
      self?.processAudioBuffer(buffer, converter: converter, outputFormat: desiredFormat)
    }

    startEngine(audioEngine, completion: completion)
  }

  private func startEngine(_ audioEngine: AVAudioEngine, completion: @escaping (Bool) -> Void) {
    do {
      try audioEngine.start()
      isRecording = true
      startRetryCount = 0
      onRecordState?(true)
      completion(true)
    } catch {
      if startRetryCount < 1 {
        startRetryCount += 1
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        self.audioEngine = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
          self?.startAudio(completion: completion)
        }
        return
      }

      startRetryCount = 0
      completion(false)
    }
  }

  private func processAudioBuffer(
    _ buffer: AVAudioPCMBuffer,
    converter: AVAudioConverter,
    outputFormat: AVAudioFormat
  ) {
    let frameCount = AVAudioFrameCount(outputFormat.sampleRate * Double(buffer.frameLength) / buffer.format.sampleRate)
    guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: frameCount) else {
      return
    }

    var error: NSError?
    let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
      outStatus.pointee = .haveData
      return buffer
    }

    converter.convert(to: convertedBuffer, error: &error, withInputFrom: inputBlock)
    if error != nil { return }

    if let channelData = convertedBuffer.int16ChannelData {
      let gain = audioGain
      for i in 0..<Int(convertedBuffer.frameLength) {
        var sample = Float(channelData[0][i])
        sample *= gain
        sample = max(-32768, min(32767, sample))
        channelData[0][i] = Int16(sample)
      }

      let data = Data(bytes: channelData[0], count: Int(convertedBuffer.frameLength) * 2)
      DispatchQueue.main.async { [weak self] in
        self?.calculateAudioLevel(buffer: buffer)
        self?.onAudioData?(data)
      }
    }
  }

  private func calculateAudioLevel(buffer: AVAudioPCMBuffer) {
    guard let channelData = buffer.floatChannelData else { return }

    let channelDataValue = channelData.pointee
    let channelDataValueArray = stride(from: 0, to: Int(buffer.frameLength), by: buffer.stride).map { channelDataValue[$0] }

    let rms = sqrt(channelDataValueArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
    let avgPower = 20 * log10(rms)
    let normalizedValue = max(0, min(1, (avgPower + 80) / 80))

    audioLevel = CGFloat(normalizedValue)
  }
}
