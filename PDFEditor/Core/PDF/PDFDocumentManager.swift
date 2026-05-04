import PDFKit
import Foundation

final class PDFDocumentManager {
    private let tempDirectory: URL

    init() {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PDFEditor", isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    // Copies the security-scoped file into temp, then opens from there.
    // This lets us release the security scope immediately without risking lazy page loads.
    func openDocument(url: URL) throws -> PDFDocument {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        let destURL = tempDirectory.appendingPathComponent(url.lastPathComponent)
        try? FileManager.default.removeItem(at: destURL)
        try FileManager.default.copyItem(at: url, to: destURL)

        guard let doc = PDFDocument(url: destURL) else {
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

    // Copies a security-scoped URL to temp and returns the local path.
    // Use this when you need to keep the file accessible after the picker dismisses.
    func copyToTemp(url: URL) throws -> URL {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        let destURL = tempDirectory.appendingPathComponent(url.lastPathComponent)
        try? FileManager.default.removeItem(at: destURL)
        try FileManager.default.copyItem(at: url, to: destURL)
        return destURL
    }

    func pageCount(at url: URL) -> Int {
        PDFDocument(url: url)?.pageCount ?? 0
    }

    func clearTemp() {
        try? FileManager.default.removeItem(at: tempDirectory)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
}
