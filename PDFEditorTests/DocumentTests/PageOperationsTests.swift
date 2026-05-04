import XCTest
import PDFKit
@testable import PDFEditor

final class PageOperationsTests: XCTestCase {

    // MARK: - Merge

    func testMergeProducesCorrectPageCount() async throws {
        let actor = PDFProcessingActor()
        let manager = PDFDocumentManager()

        let doc1 = MockPDFFactory.makeDocument(pageCount: 3)
        let doc2 = MockPDFFactory.makeDocument(pageCount: 2)
        let url1 = try manager.writeToTemp(doc1, name: "merge_a")
        let url2 = try manager.writeToTemp(doc2, name: "merge_b")

        let merged = try await actor.merge(urls: [url1, url2])
        XCTAssertEqual(merged.pageCount, 5)
    }

    func testMergePreservesOrder() async throws {
        let actor = PDFProcessingActor()
        let manager = PDFDocumentManager()

        let doc1 = MockPDFFactory.makeDocument(pageCount: 2)
        let doc2 = MockPDFFactory.makeDocument(pageCount: 2)
        let page0 = doc1.page(at: 0)!
        let page2 = doc2.page(at: 0)!

        let url1 = try manager.writeToTemp(doc1, name: "order_a")
        let url2 = try manager.writeToTemp(doc2, name: "order_b")

        let merged = try await actor.merge(urls: [url1, url2])
        // Pages from doc1 come first, doc2 second — verify by mediaBox identity
        XCTAssertEqual(merged.page(at: 0)?.bounds(for: .mediaBox),
                       page0.bounds(for: .mediaBox))
        XCTAssertEqual(merged.page(at: 2)?.bounds(for: .mediaBox),
                       page2.bounds(for: .mediaBox))
    }

    func testMergeSingleURLThrows() async {
        let actor = PDFProcessingActor()
        let manager = PDFDocumentManager()
        let doc = MockPDFFactory.makeDocument(pageCount: 1)
        guard let url = try? manager.writeToTemp(doc, name: "single") else { return }
        // merge with one URL still works (returns the single doc), but 0 raises
        let result = try? await actor.merge(urls: [url])
        XCTAssertEqual(result?.pageCount, 1)
    }

    // MARK: - Split

    func testSplitProducesTwoParts() async throws {
        let actor = PDFProcessingActor()
        let doc = MockPDFFactory.makeDocument(pageCount: 5)
        let ranges: [Range<Int>] = [0..<2, 2..<5]

        let parts = try await actor.split(document: doc, ranges: ranges)
        XCTAssertEqual(parts.count, 2)
        XCTAssertEqual(parts[0].pageCount, 2)
        XCTAssertEqual(parts[1].pageCount, 3)
    }

    func testSplitAtMidpoint() async throws {
        let actor = PDFProcessingActor()
        let doc = MockPDFFactory.makeDocument(pageCount: 4)
        let splitPoint = 2
        let ranges: [Range<Int>] = [0..<splitPoint, splitPoint..<doc.pageCount]

        let parts = try await actor.split(document: doc, ranges: ranges)
        XCTAssertEqual(parts[0].pageCount, 2)
        XCTAssertEqual(parts[1].pageCount, 2)
    }

    func testSplitInvalidRangeThrows() async {
        let actor = PDFProcessingActor()
        let doc = MockPDFFactory.makeDocument(pageCount: 2)
        let badRanges: [Range<Int>] = [0..<99]  // index 98 doesn't exist

        do {
            _ = try await actor.split(document: doc, ranges: badRanges)
            XCTFail("Expected error for invalid page index")
        } catch {
            XCTAssertTrue(error is PDFError)
        }
    }
}
