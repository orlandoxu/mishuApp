import XCTest
@testable import MishuApp

final class HomeVoiceTranscriptAssemblerTests: XCTestCase {
  func testPreviewThenDefiniteDoesNotDuplicate() {
    var assembler = HomeVoiceTranscriptAssembler()

    let preview = HomeASRUtterance(text: "我测试一下", definite: false, startMs: 0, endMs: 600)
    XCTAssertEqual(assembler.consume([preview]), "我测试一下")

    let definite = HomeASRUtterance(text: "我测试一下", definite: true, startMs: 0, endMs: 600)
    XCTAssertEqual(assembler.consume([definite]), "我测试一下")
  }

  func testSameDefiniteFingerprintOnlyCommittedOnce() {
    var assembler = HomeVoiceTranscriptAssembler()
    let utterance = HomeASRUtterance(text: "你好", definite: true, startMs: 0, endMs: 200)

    XCTAssertEqual(assembler.consume([utterance]), "你好")
    XCTAssertEqual(assembler.consume([utterance]), "你好")
  }

  func testMergeByOverlapPreventsBoundaryDuplication() {
    var assembler = HomeVoiceTranscriptAssembler()

    let first = HomeASRUtterance(text: "我测试", definite: true, startMs: 0, endMs: 300)
    let second = HomeASRUtterance(text: "测试一下", definite: true, startMs: 301, endMs: 700)

    XCTAssertEqual(assembler.consume([first]), "我测试")
    XCTAssertEqual(assembler.consume([second]), "我测试一下")
  }

  func testLatestPreviewReplacesOlderPreview() {
    var assembler = HomeVoiceTranscriptAssembler()

    let oldPreview = HomeASRUtterance(text: "我测试", definite: false, startMs: 0, endMs: 400)
    let newPreview = HomeASRUtterance(text: "我测试一下", definite: false, startMs: 0, endMs: 600)

    XCTAssertEqual(assembler.consume([oldPreview]), "我测试")
    XCTAssertEqual(assembler.consume([newPreview]), "我测试一下")
  }

  func testResetClearsAllState() {
    var assembler = HomeVoiceTranscriptAssembler()

    let utterance = HomeASRUtterance(text: "你好", definite: true, startMs: 0, endMs: 200)
    _ = assembler.consume([utterance])
    XCTAssertEqual(assembler.currentText, "你好")

    assembler.reset()
    XCTAssertEqual(assembler.currentText, "")
  }
}
