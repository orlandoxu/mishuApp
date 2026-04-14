import XCTest
@testable import MishuApp

final class PersonNameDetectorTests: XCTestCase {
  func testDetectChineseSimpleName() {
    let names = PersonNameDetector.detect(in: "我想联系王小明").map(\.name)
    XCTAssertEqual(names, ["王小明"])
  }

  func testDetectChineseNameWithTitle() {
    let names = PersonNameDetector.detect(in: "明天提醒李总开会").map(\.name)
    XCTAssertEqual(names, ["李总"])
  }

  func testDetectEnglishFullName() {
    let names = PersonNameDetector.detect(in: "Please send message to Tim Cook").map(\.name)
    XCTAssertEqual(names, ["Tim Cook"])
  }

  func testDetectMultipleNames() {
    let names = PersonNameDetector.detect(in: "联系一下马斯克和雷军").map(\.name)
    XCTAssertEqual(names, ["马斯克", "雷军"])
  }

  func testTrimsTrailingVerbForChineseGlueCase() {
    let names = PersonNameDetector.detect(in: "帮我给张三发消息").map(\.name)
    XCTAssertEqual(names, ["张三"])
  }

  func testNoNameReturnsEmpty() {
    XCTAssertTrue(PersonNameDetector.detect(in: "今天空气不错").isEmpty)
    XCTAssertTrue(PersonNameDetector.detect(in: "   ").isEmpty)
  }

  func testRangeMatchesOriginalText() {
    let text = "请通知王小明下午开会"
    let result = PersonNameDetector.detect(in: text)
    XCTAssertEqual(result.count, 1)
    guard let range = Range(result[0].nsRange, in: text) else {
      XCTFail("range conversion failed")
      return
    }
    XCTAssertEqual(String(text[range]), "王小明")
  }
}
