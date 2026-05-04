import PDFKit
import Foundation

@MainActor
final class SplitViewModel: ObservableObject {
    @Published var splitPoint: Int = 1
    @Published var isProcessing = false
    @Published var resultURLs: [URL] = []
    @Published var errorMessage: String?

    let documentName: String
    let pageCount: Int

    private let documentURL: URL
    private let processor: PDFProcessingActor
    private let docManager: PDFDocumentManager

    init(documentURL: URL, processor: PDFProcessingActor, docManager: PDFDocumentManager) {
        self.documentURL = documentURL
        self.processor = processor
        self.docManager = docManager
        self.documentName = documentURL.lastPathComponent
        self.pageCount = PDFDocument(url: documentURL)?.pageCount ?? 0
        self.splitPoint = max(1, (self.pageCount) / 2)
    }

    var part1Count: Int { splitPoint }
    var part2Count: Int { pageCount - splitPoint }
    var canSplit: Bool  { pageCount >= 2 }
    var splitRange: ClosedRange<Double> { 1...Double(max(pageCount - 1, 1)) }

    func split() async {
        guard canSplit, splitPoint > 0, splitPoint < pageCount else {
            errorMessage = "Cannot split: need at least 2 pages"
            return
        }
        isProcessing = true
        defer { isProcessing = false }

        do {
            guard let doc = PDFDocument(url: documentURL) else {
                throw PDFError.cannotOpenDocument(documentURL)
            }
            let ranges: [Range<Int>] = [0..<splitPoint, splitPoint..<pageCount]
            let parts = try await processor.split(document: doc, ranges: ranges)
            let baseName = documentURL.deletingPathExtension().lastPathComponent
            resultURLs = try parts.enumerated().map { i, part in
                try docManager.writeToTemp(part, name: "\(baseName)_part\(i + 1)")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
