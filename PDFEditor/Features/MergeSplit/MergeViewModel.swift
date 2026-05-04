import PDFKit
import Foundation

@Observable
final class MergeViewModel {
    var selectedURLs: [URL] = []
    var isProcessing = false
    var resultURL: URL?
    var error: String?

    private let processor: PDFProcessingActor
    private let docManager: PDFDocumentManager

    init(processor: PDFProcessingActor, docManager: PDFDocumentManager) {
        self.processor = processor
        self.docManager = docManager
    }

    func addDocuments(_ urls: [URL]) {
        selectedURLs.append(contentsOf: urls)
    }

    func removeDocument(at offsets: IndexSet) {
        selectedURLs.remove(atOffsets: offsets)
    }

    func merge() async {
        guard selectedURLs.count >= 2 else {
            error = "Select at least 2 PDFs to merge"
            return
        }
        isProcessing = true
        defer { isProcessing = false }

        do {
            let merged = try await processor.merge(urls: selectedURLs)
            resultURL = try docManager.writeToTemp(merged, name: "merged")
        } catch {
            self.error = error.localizedDescription
        }
    }
}
