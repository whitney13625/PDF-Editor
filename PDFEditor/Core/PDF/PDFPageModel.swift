import UIKit

struct PDFPageModel: Identifiable, Sendable {
    let id: UUID
    var pageIndex: Int  // mutable so we can reindex after delete
    var rotation: Int          // 0, 90, 180, 270
    var thumbnail: UIImage?

    init(pageIndex: Int, rotation: Int = 0, thumbnail: UIImage? = nil) {
        self.id = UUID()
        self.pageIndex = pageIndex
        self.rotation = rotation
        self.thumbnail = thumbnail
    }
}
