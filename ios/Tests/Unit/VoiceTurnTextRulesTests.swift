import XCTest
@testable import MishuApp

final class VoiceTurnTextRulesTests: XCTestCase {
  func testMergeClarificationInput() {
    let merged = TextClean.joinAsk(originInput: "帮我记保养", supplementInput: "下周三上午")
    XCTAssertEqual(merged, "帮我记保养；补充说明：下周三上午")
  }
}
