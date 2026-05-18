import XCTest

final class MishuAppUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  func testHomeVoiceSurfaceRenders() throws {
    let app = XCUIApplication()
    app.launchArguments.append("--ui-testing")
    app.launch()

    XCTAssertTrue(app.otherElements["home_main_root"].waitForExistence(timeout: 8))
  }

  func testContactsRouteAndListSearch() throws {
    let app = XCUIApplication()
    app.launchArguments += ["--ui-testing", "--ui-route", "contacts"]
    app.launch()

    XCTAssertTrue(app.buttons["contacts_show_all_button"].waitForExistence(timeout: 3))
    XCTAssertTrue(app.descendants(matching: .any)["contacts_gender_icon"].waitForExistence(timeout: 3))
    XCTAssertTrue(app.descendants(matching: .any)["contacts_rotating_quote"].waitForExistence(timeout: 3))
    app.buttons["contacts_show_all_button"].tap()
    XCTAssertTrue(app.staticTexts["全部联系人"].waitForExistence(timeout: 3))

    let sarahRow = app.buttons["contact_list_item_sarah"].firstMatch
    XCTAssertTrue(sarahRow.waitForExistence(timeout: 3))
    sarahRow.tap()
    XCTAssertTrue(app.buttons["contacts_show_all_button"].waitForExistence(timeout: 3))
  }

  func testFoodMemoryRouteAndInteractions() throws {
    let app = XCUIApplication()
    app.launchArguments += ["--ui-testing", "--ui-route", "foodMemory"]
    app.launch()

    XCTAssertTrue(app.staticTexts["美食记忆"].waitForExistence(timeout: 8))
    XCTAssertTrue(app.buttons["food_memory_toggle_map"].waitForExistence(timeout: 3))
    XCTAssertTrue(app.descendants(matching: .any)["food_memory_card_1"].waitForExistence(timeout: 3))

    app.buttons["food_memory_toggle_map"].tap()
    XCTAssertTrue(app.buttons["food_memory_month_2026_05"].waitForExistence(timeout: 3))
    app.buttons["food_memory_month_2026_05"].tap()

    app.buttons["food_memory_toggle_map"].tap()
    XCTAssertTrue(app.descendants(matching: .any)["food_memory_card_4"].waitForExistence(timeout: 3))
  }
}
