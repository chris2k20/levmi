import XCTest

final class LevmiSmokeUITests: XCTestCase {
    @MainActor
    func testAppLaunchesAndShowsRoot() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.otherElements["root"].waitForExistence(timeout: 10))
    }
}
