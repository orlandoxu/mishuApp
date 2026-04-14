import XCTest
@testable import MishuApp

final class MemoryIntentPlanTests: XCTestCase {
  func testParseJSONBlock() {
    let raw = """
    好的，结果如下：
    {"intent":"store","should_store":true,"store_text":"明天早上9点年检","should_retrieve":false,"retrieve_query":"","direct_reply":"好的，我记下了。"}
    """
    let plan = IntentPlan.parse(from: raw)
    XCTAssertNotNil(plan)
    XCTAssertEqual(plan?.intent, .store)
    XCTAssertEqual(plan?.shouldSave, true)
    XCTAssertEqual(plan?.saveText, "明天早上9点年检")
    XCTAssertEqual(plan?.shouldFind, false)
  }

  func testFallbackIsSafetyClarify() {
    let plan = IntentPlan.fallback(for: "随便聊聊")
    XCTAssertEqual(plan.intent, .clarify)
    XCTAssertEqual(plan.normalizedIntent, .clarify)
    XCTAssertTrue(plan.needConfirm)
    XCTAssertFalse(plan.askText.isEmpty)
  }

  func testParseCompatibleWithLegacySchema() {
    let raw = """
    {"should_store":false,"store_text":"","should_retrieve":true,"retrieve_query":"我上次记了什么","direct_reply":""}
    """
    let plan = IntentPlan.parse(from: raw)
    XCTAssertNotNil(plan)
    XCTAssertEqual(plan?.intent, .unknown)
    XCTAssertEqual(plan?.normalizedIntent, .retrieve)
  }
}
