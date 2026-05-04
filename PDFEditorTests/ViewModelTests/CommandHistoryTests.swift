import XCTest
import PDFKit
@testable import PDFEditor

final class CommandHistoryTests: XCTestCase {

    // MARK: - ReorderPageCommand

    func testReorderForward() {
        let doc = MockPDFFactory.makeDocument(pageCount: 4)
        let originalPage0 = doc.page(at: 0)!

        // Move page at index 0 to slot 3 (ends up at index 2)
        let cmd = ReorderPageCommand(document: doc, fromIndex: 0, toIndex: 3)
        cmd.execute()

        XCTAssertEqual(doc.pageCount, 4)
        XCTAssertTrue(doc.page(at: 2) === originalPage0, "Page should be at index 2")

        cmd.undo()
        XCTAssertTrue(doc.page(at: 0) === originalPage0, "Page should be restored to index 0")
    }

    func testReorderBackward() {
        let doc = MockPDFFactory.makeDocument(pageCount: 4)
        let originalPage3 = doc.page(at: 3)!

        // Move page at index 3 to slot 0 (ends up at index 0)
        let cmd = ReorderPageCommand(document: doc, fromIndex: 3, toIndex: 0)
        cmd.execute()

        XCTAssertEqual(doc.pageCount, 4)
        XCTAssertTrue(doc.page(at: 0) === originalPage3, "Page should be at index 0")

        cmd.undo()
        XCTAssertTrue(doc.page(at: 3) === originalPage3, "Page should be restored to index 3")
    }

    // MARK: - DeletePageCommand

    func testDeleteAndUndo() {
        let doc = MockPDFFactory.makeDocument(pageCount: 3)
        let pageToDelete = doc.page(at: 1)!

        let cmd = DeletePageCommand(document: doc, page: pageToDelete, index: 1)
        cmd.execute()
        XCTAssertEqual(doc.pageCount, 2)

        cmd.undo()
        XCTAssertEqual(doc.pageCount, 3)
        XCTAssertTrue(doc.page(at: 1) === pageToDelete)
    }

    // MARK: - RotatePageCommand

    func testRotateAndUndo() {
        let doc = MockPDFFactory.makeDocument(pageCount: 1)
        let page = doc.page(at: 0)!
        page.rotation = 0

        let cmd = RotatePageCommand(page: page, degrees: 90)
        cmd.execute()
        XCTAssertEqual(page.rotation, 90)

        cmd.undo()
        XCTAssertEqual(page.rotation, 0)
    }

    // MARK: - CommandHistory

    func testUndoRedoCycle() {
        let doc = MockPDFFactory.makeDocument(pageCount: 3)
        let page = doc.page(at: 0)!
        let history = CommandHistory()

        XCTAssertFalse(history.canUndo)
        XCTAssertFalse(history.canRedo)

        history.execute(RotatePageCommand(page: page, degrees: 90))
        XCTAssertTrue(history.canUndo)
        XCTAssertFalse(history.canRedo)
        XCTAssertEqual(page.rotation, 90)

        history.undo()
        XCTAssertFalse(history.canUndo)
        XCTAssertTrue(history.canRedo)
        XCTAssertEqual(page.rotation, 0)

        history.redo()
        XCTAssertTrue(history.canUndo)
        XCTAssertFalse(history.canRedo)
        XCTAssertEqual(page.rotation, 90)
    }

    func testRegisterDoesNotExecute() {
        let doc = MockPDFFactory.makeDocument(pageCount: 1)
        let page = doc.page(at: 0)!
        page.rotation = 0
        let history = CommandHistory()

        let cmd = RotatePageCommand(page: page, degrees: 90)
        history.register(cmd)  // should NOT rotate the page

        XCTAssertEqual(page.rotation, 0, "register() must not execute the command")
        XCTAssertTrue(history.canUndo)

        history.undo()
        // undo of a 90° rotate = -90° + 360 = 270°
        XCTAssertEqual(page.rotation, 270)
    }
}
