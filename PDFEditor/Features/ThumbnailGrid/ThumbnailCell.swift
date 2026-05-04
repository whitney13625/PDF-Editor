import SwiftUI

struct ThumbnailCell: View {
    let page: PDFPageModel

    var body: some View {
        VStack(spacing: 6) {
            Group {
                if let image = page.thumbnail {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                } else {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay(ProgressView())
                }
            }
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .shadow(color: .black.opacity(0.12), radius: 3, x: 0, y: 1)

            Text("Page \(page.pageIndex + 1)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct PageContextMenu: View {
    @ObservedObject var vm: ThumbnailGridViewModel
    let pageIndex: Int

    var body: some View {
        Button("Rotate 90°", systemImage: "rotate.right") {
            vm.rotatePage(at: pageIndex, degrees: 90)
        }
        Divider()
        Button("Delete Page", systemImage: "trash", role: .destructive) {
            vm.deletePage(at: IndexSet(integer: pageIndex))
        }
    }
}
