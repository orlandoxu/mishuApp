import XCTest
@testable import MishuApp

final class MemoryIntentPlanTests: XCTestCase {
  func testParseJSONBlock() {
    let raw = """
    好的，结果如下：
    {"intent":"store","should_store":true,"store_text":"明天早上9点年检","should_retrieve":false,"retrieve_query":"","direct_reply":"好的，我记下了。"}
    """
    let plan = MemoryIntentPlan.parse(from: raw)
    XCTAssertNotNil(plan)
    XCTAssertEqual(plan?.intent, .store)
    XCTAssertEqual(plan?.shouldStore, true)
    XCTAssertEqual(plan?.storeText, "明天早上9点年检")
    XCTAssertEqual(plan?.shouldRetrieve, false)
  }

  func testFallbackDetectsRetrieveIntent() {
    let plan = MemoryIntentPlan.fallback(for: "帮我查一下之前记过什么")
    XCTAssertEqual(plan.normalizedIntent, .retrieve)
    XCTAssertEqual(plan.shouldRetrieve, true)
    XCTAssertEqual(plan.shouldStore, false)
  }

  func testFallbackDetectsAmendIntent() {
    let plan = MemoryIntentPlan.fallback(for: "把之前提醒我保养改成下周三")
    XCTAssertEqual(plan.normalizedIntent, .amend)
    XCTAssertTrue(plan.requiresConfirmation)
    XCTAssertFalse(plan.amendmentText.isEmpty)
  }

  func testParseCompatibleWithLegacySchema() {
    let raw = """
    {"should_store":false,"store_text":"","should_retrieve":true,"retrieve_query":"我上次记了什么","direct_reply":""}
    """
    let plan = MemoryIntentPlan.parse(from: raw)
    XCTAssertNotNil(plan)
    XCTAssertEqual(plan?.intent, .unknown)
    XCTAssertEqual(plan?.normalizedIntent, .retrieve)
  }
}
