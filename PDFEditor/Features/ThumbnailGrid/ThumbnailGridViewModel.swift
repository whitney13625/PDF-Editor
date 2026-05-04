import PDFKit
import SwiftUI

@Observable
final class ThumbnailGridViewModel {
    var pages: [PDFPageModel] = []
    var isLoading = false
    var error: String?

    private var document: PDFDocument?
    private let processor: PDFProcessingActor
    private let docManager: PDFDocumentManager
    private let history: CommandHistory

    init(processor: PDFProcessingActor, docManager: PDFDocumentManager, history: CommandHistory) {
        self.processor = processor
        self.docManager = docManager
        self.history = history
    }

    func loadDocument(url: URL) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let doc = try docManager.openDocument(url: url)
            let thumbnails = await processor.renderThumbnails(for: doc, size: CGSize(width: 160, height: 220))
            document = doc
            pages = thumbnails
        } catch {
            self.error = error.localizedDescription
        }
    }

    func movePage(from source: IndexSet, to destination: Int) {
        guard let fromIndex = source.first, let doc = document else { return }
        let command = ReorderPageCommand(document: doc, fromIndex: fromIndex, toIndex: destination)
        history.execute(command)
        pages.move(fromOffsets: source, toOffset: destination)
    }

    func deletePage(at offsets: IndexSet) {
        guard let doc = document else { return }
        for index in offsets.sorted(by: >) {
            guard let page = doc.page(at: index) else { continue }
            let command = DeletePageCommand(document: doc, page: page, index: index)
            history.execute(command)
            pages.remove(at: index)
        }
    }

    func rotatePage(at index: Int, degrees: Int = 90) {
        guard let page = document?.page(at: index) else { return }
        let command = RotatePageCommand(page: page, degrees: degrees)
        history.execute(command)
        pages[index] = PDFPageModel(pageIndex: index, rotation: (pages[index].rotation + degrees) % 360)
        refreshThumbnail(at: index, page: page)
    }

    func currentDocument() -> PDFDocument? { document }

    private func refreshThumbnail(at index: Int, page: PDFPage) {
        Task {
            let thumb = await processor.renderThumbnail(for: page, size: CGSize(width: 160, height: 220))
            pages[index] = PDFPageModel(pageIndex: index, rotation: pages[index].rotation, thumbnail: thumb)
        }
    }
}
