import SwiftUI

// Wraps UIActivityViewController. Cleans up temp URLs after the activity completes.
struct ExportView: UIViewControllerRepresentable {
    let urls: [URL]
    let onDismiss: () -> Void
    private let cleanup: [URL]  // temp files to delete after share

    init(url: URL, cleanup: [URL] = [], onDismiss: @escaping () -> Void) {
        self.urls = [url]
        self.cleanup = cleanup.isEmpty ? [url] : cleanup
        self.onDismiss = onDismiss
    }

    init(urls: [URL], cleanup: [URL] = [], onDismiss: @escaping () -> Void) {
        self.urls = urls
        self.cleanup = cleanup.isEmpty ? urls : cleanup
        self.onDismiss = onDismiss
    }

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: urls, applicationActivities: nil)
        let filesToDelete = cleanup
        vc.completionWithItemsHandler = { _, _, _, _ in
            for url in filesToDelete {
                try? FileManager.default.removeItem(at: url)
            }
            onDismiss()
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
