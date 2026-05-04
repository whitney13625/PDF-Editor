import PDFKit
import Foundation

struct MergeItem: Identifiable {
    let id = UUID()
    let name: String
    let url: URL       // always a local temp copy — no security scope needed
    let pageCount: Int
}

@MainActor
final class MergeViewModel: ObservableObject {
    @Published var items: [MergeItem] = []
    @Published var isProcessing = false
    @Published var resultURL: URL?
    @Published var errorMessage: String?

    private let processor: PDFProcessingActor
    private let docManager: PDFDocumentManager

    init(processor: PDFProcessingActor, docManager: PDFDocumentManager) {
        self.processor = processor
        self.docManager = docManager
    }

    // Copies each picked URL to temp, reads page count, appends to list.
    func addDocuments(_ urls: [URL]) {
        for url in urls {
            guard let tempURL = try? docManager.copyToTemp(url: url) else { continue }
            let count = docManager.pageCount(at: tempURL)
            items.append(MergeItem(name: url.lastPathComponent, url: tempURL, pageCount: count))
        }
    }

    func removeItems(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }

    func moveItem(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
    }

    func merge() async {
        guard items.count >= 2 else {
            errorMessage = "Select at least 2 PDFs to merge"
            return
        }
        isProcessing = true
        defer { isProcessing = false }

        do {
            let urls = items.map(\.url)
            let merged = try await processor.merge(urls: urls)
            resultURL = try docManager.writeToTemp(merged, name: "merged")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
