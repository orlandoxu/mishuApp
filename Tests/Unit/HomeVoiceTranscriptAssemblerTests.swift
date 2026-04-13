import XCTest
@testable import MishuApp

final class HomeVoiceTranscriptAssemblerTests: XCTestCase {
  func testPreviewThenDefiniteDoesNotDuplicate() {
    var assembler = VoiceTextAssembler()

    let preview = AsrUtterance(text: "我测试一下", definite: false, startMs: 0, endMs: 600)
    XCTAssertEqual(assembler.consume([preview]), "我测试一下")

    let definite = AsrUtterance(text: "我测试一下", definite: true, startMs: 0, endMs: 600)
    XCTAssertEqual(assembler.consume([definite]), "我测试一下")
  }

  func testSameDefiniteFingerprintOnlyCommittedOnce() {
    var assembler = VoiceTextAssembler()
    let utterance = AsrUtterance(text: "你好", definite: true, startMs: 0, endMs: 200)

    XCTAssertEqual(assembler.consume([utterance]), "你好")
    XCTAssertEqual(assembler.consume([utterance]), "你好")
  }

  func testMergeByOverlapPreventsBoundaryDuplication() {
    var assembler = VoiceTextAssembler()

    let first = AsrUtterance(text: "我测试", definite: true, startMs: 0, endMs: 300)
    let second = AsrUtterance(text: "测试一下", definite: true, startMs: 301, endMs: 700)

    XCTAssertEqual(assembler.consume([first]), "我测试")
    XCTAssertEqual(assembler.consume([second]), "我测试一下")
  }

  func testLatestPreviewReplacesOlderPreview() {
    var assembler = VoiceTextAssembler()

    let oldPreview = AsrUtterance(text: "我测试", definite: false, startMs: 0, endMs: 400)
    let newPreview = AsrUtterance(text: "我测试一下", definite: false, startMs: 0, endMs: 600)

    XCTAssertEqual(assembler.consume([oldPreview]), "我测试")
    XCTAssertEqual(assembler.consume([newPreview]), "我测试一下")
  }

  func testResetClearsAllState() {
    var assembler = VoiceTextAssembler()

    let utterance = AsrUtterance(text: "你好", definite: true, startMs: 0, endMs: 200)
    _ = assembler.consume([utterance])
    XCTAssertEqual(assembler.currentText, "你好")

    assembler.reset()
    XCTAssertEqual(assembler.currentText, "")
  }
}
