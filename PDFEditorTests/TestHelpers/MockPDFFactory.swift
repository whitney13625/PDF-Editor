import PDFKit
import Foundation

enum MockPDFFactory {
    static func makeDocument(pageCount: Int) -> PDFDocument {
        let doc = PDFDocument()
        for i in 0..<pageCount {
            let page = PDFPage()
            doc.insert(page, at: i)
        }
        return doc
    }
}
