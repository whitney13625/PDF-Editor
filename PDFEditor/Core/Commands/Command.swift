import PDFKit

protocol Command {
    func execute()
    func undo()
}

struct RotatePageCommand: Command {
    let page: PDFPage
    let degrees: Int

    func execute() { page.rotation = (page.rotation + degrees) % 360 }
    func undo()    { page.rotation = (page.rotation - degrees + 360) % 360 }
}

struct DeletePageCommand: Command {
    let document: PDFDocument
    let page: PDFPage
    let index: Int

    func execute() { document.removePage(at: index) }
    func undo()    { document.insert(page, at: index) }
}

struct ReorderPageCommand: Command {
    let document: PDFDocument
    let fromIndex: Int
    let toIndex: Int

    func execute() { movePage(from: fromIndex, to: toIndex) }
    func undo()    { movePage(from: toIndex, to: fromIndex) }

    private func movePage(from source: Int, to destination: Int) {
        guard let page = document.page(at: source) else { return }
        document.removePage(at: source)
        document.insert(page, at: destination)
    }
}
