import PDFKit
import Foundation

final class PDFDocumentManager {
    private let tempDirectory: URL

    init() {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PDFEditor", isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    func openDocument(url: URL) throws -> PDFDocument {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        guard let doc = PDFDocument(url: url) else {
            throw PDFError.cannotOpenDocument(url)
        }
        return doc
    }

    func writeToTemp(_ document: PDFDocument, name: String = "output") throws -> URL {
        let outputURL = tempDirectory.appendingPathComponent("\(name).pdf")
        guard document.write(to: outputURL) else {
            throw PDFError.emptyDocument
        }
        return outputURL
    }

    func clearTemp() {
        try? FileManager.default.removeItem(at: tempDirectory)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
}
