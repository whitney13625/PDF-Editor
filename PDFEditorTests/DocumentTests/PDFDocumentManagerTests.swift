import XCTest
import PDFKit
@testable import PDFEditor

final class PDFDocumentManagerTests: XCTestCase {
    func testOpenNonExistentFileThrows() {
        let manager = PDFDocumentManager()
        let bogusURL = URL(fileURLWithPath: "/tmp/does_not_exist.pdf")
        XCTAssertThrowsError(try manager.openDocument(url: bogusURL))
    }

    func testWriteToTempProducesReadableFile() throws {
        let manager = PDFDocumentManager()
        let doc = MockPDFFactory.makeDocument(pageCount: 2)
        let url = try manager.writeToTemp(doc, name: "test_write")
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        let reread = PDFDocument(url: url)
        XCTAssertNotNil(reread)
        XCTAssertEqual(reread?.pageCount, 2)
    }
}
