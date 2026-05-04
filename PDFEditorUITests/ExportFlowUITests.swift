import XCTest

final class ExportFlowUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testImportButtonExists() {
        XCTAssertTrue(app.buttons["Import PDF"].exists)
    }
}
