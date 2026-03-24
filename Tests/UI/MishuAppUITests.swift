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
    XCTAssertTrue(app.buttons["home_voice_mic_button"].exists)
    XCTAssertTrue(app.staticTexts["home_mascot_status_text"].exists)
  }
}
