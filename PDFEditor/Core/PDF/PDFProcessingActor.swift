import PDFKit
import UIKit

actor PDFProcessingActor {

    // MARK: - Thumbnails

    func renderThumbnail(for page: PDFPage, size: CGSize) -> UIImage {
        let bounds = page.bounds(for: .mediaBox)
        let scale = min(size.width / bounds.width, size.height / bounds.height)
        let targetSize = CGSize(width: bounds.width * scale, height: bounds.height * scale)

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(CGRect(origin: .zero, size: targetSize))
            ctx.cgContext.scaleBy(x: scale, y: scale)
            page.draw(with: .mediaBox, to: ctx.cgContext)
        }
    }

    func renderThumbnails(for document: PDFDocument, size: CGSize) -> [PDFPageModel] {
        (0..<document.pageCount).compactMap { index in
            guard let page = document.page(at: index) else { return nil }
            let thumbnail = renderThumbnail(for: page, size: size)
            let rotation = page.rotation
            return PDFPageModel(pageIndex: index, rotation: rotation, thumbnail: thumbnail)
        }
    }

    // MARK: - Merge

    func merge(urls: [URL]) throws -> PDFDocument {
        let merged = PDFDocument()
        var insertIndex = 0

        for url in urls {
            guard let doc = PDFDocument(url: url) else {
                throw PDFError.cannotOpenDocument(url)
            }
            for pageIndex in 0..<doc.pageCount {
                guard let page = doc.page(at: pageIndex) else { continue }
                merged.insert(page, at: insertIndex)
                insertIndex += 1
            }
        }

        guard merged.pageCount > 0 else { throw PDFError.emptyDocument }
        return merged
    }

    // MARK: - Split

    func split(document: PDFDocument, ranges: [Range<Int>]) throws -> [PDFDocument] {
        try ranges.map { range in
            let part = PDFDocument()
            for (newIndex, pageIndex) in range.enumerated() {
                guard let page = document.page(at: pageIndex) else {
                    throw PDFError.invalidPageIndex(pageIndex)
                }
                part.insert(page, at: newIndex)
            }
            return part
        }
    }

    // MARK: - Page operations

    func rotatePage(_ page: PDFPage, by degrees: Int) {
        page.rotation = (page.rotation + degrees) % 360
    }
}

enum PDFError: LocalizedError {
    case cannotOpenDocument(URL)
    case emptyDocument
    case invalidPageIndex(Int)

    var errorDescription: String? {
        switch self {
        case .cannotOpenDocument(let url): return "Cannot open PDF at \(url.lastPathComponent)"
        case .emptyDocument: return "The resulting PDF has no pages"
        case .invalidPageIndex(let i): return "Invalid page index: \(i)"
        }
    }
}
