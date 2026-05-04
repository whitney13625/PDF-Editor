import PDFKit
import SwiftUI

@MainActor
final class ThumbnailGridViewModel: ObservableObject {
    @Published var pages: [PDFPageModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private(set) var documentName: String = "document"
    private var document: PDFDocument?
    private var renderTask: Task<Void, Never>?

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
        renderTask?.cancel()
        isLoading = true

        do {
            let doc = try docManager.openDocument(url: url)
            documentName = url.deletingPathExtension().lastPathComponent
            document = doc

            // Show placeholder grid immediately so the user sees structure right away
            pages = (0..<doc.pageCount).map { PDFPageModel(pageIndex: $0) }
            isLoading = false

            // Render thumbnails one by one in the background
            renderTask = Task { [weak self] in
                await self?.renderProgressively(doc: doc)
            }
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    // Re-render from current PDFDocument state after undo/redo.
    // Shows page structure immediately, fills thumbnails progressively.
    func reloadPages() async {
        guard let doc = document else { return }
        renderTask?.cancel()

        pages = (0..<doc.pageCount).map { i in
            let rotation = doc.page(at: i).map { Int($0.rotation) } ?? 0
            return PDFPageModel(pageIndex: i, rotation: rotation)
        }

        renderTask = Task { [weak self] in
            await self?.renderProgressively(doc: doc)
        }
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
        Task { await refreshSingleThumbnail(at: index, page: page) }
    }

    // MARK: - Drag-to-reorder helpers

    func movePagePreview(from source: IndexSet, to destination: Int) {
        guard let fromIndex = source.first, let doc = document else { return }
        let command = ReorderPageCommand(document: doc, fromIndex: fromIndex, toIndex: destination)
        command.execute()
        pages.move(fromOffsets: source, toOffset: destination)
    }

    func commitDrag(startIndex: Int, draggingID: UUID) {
        guard let doc = document,
              let endIndex = pages.firstIndex(where: { $0.id == draggingID }),
              startIndex != endIndex else { return }
        let swiftUISlot = endIndex > startIndex ? endIndex + 1 : endIndex
        let command = ReorderPageCommand(document: doc, fromIndex: startIndex, toIndex: swiftUISlot)
        history.register(command)
    }

    // MARK: - Accessors

    func currentDocument() -> PDFDocument? { document }

    // MARK: - Private

    private func renderProgressively(doc: PDFDocument) async {
        for i in 0..<doc.pageCount {
            guard !Task.isCancelled else { break }
            guard let page = doc.page(at: i), i < pages.count else { break }
            let image = await processor.renderThumbnail(for: page, size: thumbnailSize)
            guard !Task.isCancelled, i < pages.count else { break }
            pages[i].thumbnail = image
        }
    }

    private func refreshSingleThumbnail(at index: Int, page: PDFPage) async {
        let thumb = await processor.renderThumbnail(for: page, size: thumbnailSize)
        guard index < pages.count else { return }
        pages[index].thumbnail = thumb
    }

    private func reindexPages() {
        for i in pages.indices { pages[i].pageIndex = i }
    }
}
