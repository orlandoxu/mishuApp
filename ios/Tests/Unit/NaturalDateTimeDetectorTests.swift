import XCTest
@testable import MishuApp

final class NaturalDateTimeDetectorTests: XCTestCase {
  func testDetectAbsoluteChineseDateTime() throws {
    let input = "请在2026年04月20日 15:30提醒我保养"
    let results = NaturalDateTimeDetector.detect(in: input)
    XCTAssertEqual(results.count, 1)
    XCTAssertEqual(results.first?.matchedText, "2026年04月20日 15:30")

    let calendar = Calendar(identifier: .gregorian)
    let components = calendar.dateComponents(in: .current, from: try XCTUnwrap(results.first?.date))
    XCTAssertEqual(components.year, 2026)
    XCTAssertEqual(components.month, 4)
    XCTAssertEqual(components.day, 20)
    XCTAssertEqual(components.hour, 15)
    XCTAssertEqual(components.minute, 30)
  }

  func testDetectAbsoluteSlashDateTime() throws {
    let input = "会议时间是 2026/05/01 08:00"
    let results = NaturalDateTimeDetector.detect(in: input)
    XCTAssertEqual(results.count, 1)
    XCTAssertEqual(results.first?.matchedText, "2026/05/01 08:00")

    let calendar = Calendar(identifier: .gregorian)
    let components = calendar.dateComponents(in: .current, from: try XCTUnwrap(results.first?.date))
    XCTAssertEqual(components.year, 2026)
    XCTAssertEqual(components.month, 5)
    XCTAssertEqual(components.day, 1)
    XCTAssertEqual(components.hour, 8)
    XCTAssertEqual(components.minute, 0)
  }

  func testDetectMultipleDateTimes() throws {
    let input = "4月20日上午9点开会，4月21日下午3点复盘"
    let results = NaturalDateTimeDetector.detect(in: input)
    XCTAssertEqual(results.count, 2)
    XCTAssertEqual(results.map(\.matchedText), ["4月20日上午9点", "4月21日下午3点"])

    let calendar = Calendar(identifier: .gregorian)
    let first = calendar.dateComponents(in: .current, from: try XCTUnwrap(results.first?.date))
    let second = calendar.dateComponents(in: .current, from: try XCTUnwrap(results.last?.date))
    XCTAssertEqual(first.hour, 9)
    XCTAssertEqual(second.hour, 15)
  }

  func testDetectRelativeDateKeyword() {
    let input = "明天提醒我缴停车费"
    let results = NaturalDateTimeDetector.detect(in: input)
    XCTAssertEqual(results.count, 1)
    XCTAssertEqual(results.first?.matchedText, "明天")
  }

  func testNoDateReturnsEmpty() {
    XCTAssertTrue(NaturalDateTimeDetector.detect(in: "只是聊聊天").isEmpty)
    XCTAssertTrue(NaturalDateTimeDetector.detect(in: "").isEmpty)
  }

  func testRangeMatchesOriginalText() throws {
    let input = "把年检安排在4月30日下午3点"
    let results = NaturalDateTimeDetector.detect(in: input)
    XCTAssertEqual(results.count, 1)

    guard let range = Range(try XCTUnwrap(results.first?.nsRange), in: input) else {
      XCTFail("range conversion failed")
      return
    }
    XCTAssertEqual(String(input[range]), "4月30日下午3点")
  }
}
