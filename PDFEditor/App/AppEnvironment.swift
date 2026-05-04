import Foundation

final class AppEnvironment: ObservableObject {
    let pdfProcessor = PDFProcessingActor()
    let commandHistory = CommandHistory()
    let documentManager = PDFDocumentManager()
}
