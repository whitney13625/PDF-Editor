import PDFKit
import Foundation

final class SplitViewModel: ObservableObject {
    @Published var splitPoint: Int = 1
    @Published var isProcessing = false
    @Published var resultURLs: [URL] = []
    @Published var error: String?

    private let processor: PDFProcessingActor
    private let docManager: PDFDocumentManager

    init(processor: PDFProcessingActor, docManager: PDFDocumentManager) {
        self.processor = processor
        self.docManager = docManager
    }

    func split(document: PDFDocument) async {
        let total = document.pageCount
        guard splitPoint > 0 && splitPoint < total else {
            error = "Split point must be between 1 and \(total - 1)"
            return
        }

        isProcessing = true
        defer { isProcessing = false }

        do {
            let ranges: [Range<Int>] = [0..<splitPoint, splitPoint..<total]
            let parts = try await processor.split(document: document, ranges: ranges)
            resultURLs = try parts.enumerated().map { i, doc in
                try docManager.writeToTemp(doc, name: "split_part\(i + 1)")
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
