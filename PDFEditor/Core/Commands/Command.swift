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

// toIndex is the SwiftUI move(fromOffsets:toOffset:) slot, NOT the final array index.
// SwiftUI slot semantics: element is inserted BEFORE the element currently at that slot,
// after the source element has been removed. This means the actual insert position in
// PDFDocument differs by -1 when the slot is greater than the source.
struct ReorderPageCommand: Command {
    let document: PDFDocument
    let fromIndex: Int  // original position
    let toIndex: Int    // SwiftUI move slot (before-removal target slot)

    func execute() {
        applyMove(from: fromIndex, swiftUISlot: toIndex)
    }

    func undo() {
        // After execute(), the element sits at this final array index:
        let finalIndex = toIndex > fromIndex ? toIndex - 1 : toIndex
        // To move it back to fromIndex, the SwiftUI slot is:
        let undoSlot = fromIndex >= finalIndex ? fromIndex + 1 : fromIndex
        applyMove(from: finalIndex, swiftUISlot: undoSlot)
    }

    private func applyMove(from source: Int, swiftUISlot slot: Int) {
        guard let page = document.page(at: source) else { return }
        document.removePage(at: source)
        // After removal, slots after source shift down by 1
        let insertAt = slot > source ? slot - 1 : slot
        document.insert(page, at: min(insertAt, document.pageCount))
    }
}
