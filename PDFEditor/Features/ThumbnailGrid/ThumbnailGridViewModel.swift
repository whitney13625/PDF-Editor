import PDFKit
import SwiftUI

@MainActor
final class ThumbnailGridViewModel: ObservableObject {
    @Published var pages: [PDFPageModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private(set) var documentName: String = "document"
    private var document: PDFDocument?
    private let processor: PDFProcessingActor
    private let docManager: PDFDocumentManager
    private let history: CommandHistory

    private let thumbnailSize = CGSize(width: 160, height: 220)

    init(processor: PDFProcessingActor, docManager: PDFDocumentManager, history: CommandHistory) {
        self.processor = processor
        self.docManager = docManager
        self.history = history
    }

    // MARK: - Load

    func loadDocument(url: URL) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let doc = try docManager.openDocument(url: url)
            let thumbnails = await processor.renderThumbnails(for: doc, size: thumbnailSize)
            documentName = url.deletingPathExtension().lastPathComponent
            document = doc
            pages = thumbnails
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // Re-renders all pages from the current PDFDocument state.
    // Call this after undo/redo so the view reflects the document's new state.
    func reloadPages() async {
        guard let doc = document else { return }
        let thumbnails = await processor.renderThumbnails(for: doc, size: thumbnailSize)
        pages = thumbnails
    }

    // MARK: - Page operations (recorded in history)

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
        reindexPages()
    }

    func rotatePage(at index: Int, degrees: Int = 90) {
        guard let page = document?.page(at: index) else { return }
        let command = RotatePageCommand(page: page, degrees: degrees)
        history.execute(command)
        pages[index] = PDFPageModel(
            pageIndex: index,
            rotation: (pages[index].rotation + degrees) % 360,
            thumbnail: pages[index].thumbnail
        )
        Task { await refreshThumbnail(at: index, page: page) }
    }

    // MARK: - Drag-to-reorder helpers

    // Visual-only move used during drag. Updates both the view model and the
    // underlying PDFDocument so state stays in sync, but does NOT push to history.
    // One consolidated ReorderPageCommand is registered via commitDrag() on drop.
    func movePagePreview(from source: IndexSet, to destination: Int) {
        guard let fromIndex = source.first, let doc = document else { return }
        let command = ReorderPageCommand(document: doc, fromIndex: fromIndex, toIndex: destination)
        command.execute()  // sync PDFDocument
        pages.move(fromOffsets: source, toOffset: destination)
    }

    // Called when a drag completes. Records a single undo step covering the full
    // movement from startIndex to the element's current position.
    func commitDrag(startIndex: Int, draggingID: UUID) {
        guard let doc = document,
              let endIndex = pages.firstIndex(where: { $0.id == draggingID }),
              startIndex != endIndex else { return }
        let swiftUISlot = endIndex > startIndex ? endIndex + 1 : endIndex
        let command = ReorderPageCommand(document: doc, fromIndex: startIndex, toIndex: swiftUISlot)
        history.register(command)  // already applied, just record for undo
    }

    // MARK: - Accessors

    func currentDocument() -> PDFDocument? { document }

    // MARK: - Private

    private func refreshThumbnail(at index: Int, page: PDFPage) async {
        let thumb = await processor.renderThumbnail(for: page, size: thumbnailSize)
        guard index < pages.count else { return }
        pages[index] = PDFPageModel(pageIndex: index, rotation: pages[index].rotation, thumbnail: thumb)
    }

    private func reindexPages() {
        for i in pages.indices { pages[i].pageIndex = i }
    }
}
