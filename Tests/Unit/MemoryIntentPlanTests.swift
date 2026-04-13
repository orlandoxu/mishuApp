import XCTest
@testable import MishuApp

final class MemoryIntentPlanTests: XCTestCase {
  func testParseJSONBlock() {
    let raw = """
    好的，结果如下：
    {"should_store":true,"store_text":"明天早上9点年检","should_retrieve":false,"retrieve_query":"","direct_reply":"好的，我记下了。"}
    """
    let plan = MemoryIntentPlan.parse(from: raw)
    XCTAssertNotNil(plan)
    XCTAssertEqual(plan?.shouldStore, true)
    XCTAssertEqual(plan?.storeText, "明天早上9点年检")
    XCTAssertEqual(plan?.shouldRetrieve, false)
  }

  func testFallbackDetectsRetrieveIntent() {
    let plan = MemoryIntentPlan.fallback(for: "帮我查一下之前记过什么")
    XCTAssertEqual(plan.shouldRetrieve, true)
    XCTAssertEqual(plan.shouldStore, false)
  }
}
