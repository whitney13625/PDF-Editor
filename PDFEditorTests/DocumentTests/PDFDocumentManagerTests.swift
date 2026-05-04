import XCTest
@testable import PDFEditor

final class PDFDocumentManagerTests: XCTestCase {
    func testOpenNonExistentFileThrows() throws {
        let manager = PDFDocumentManager()
        let bogusURL = URL(fileURLWithPath: "/tmp/does_not_exist.pdf")
        XCTAssertThrowsError(try manager.openDocument(url: bogusURL))
    }
}
