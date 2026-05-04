import SwiftUI

struct ExportView: UIViewControllerRepresentable {
    let urls: [URL]
    let onDismiss: () -> Void

    init(url: URL, onDismiss: @escaping () -> Void) {
        self.urls = [url]
        self.onDismiss = onDismiss
    }

    init(urls: [URL], onDismiss: @escaping () -> Void) {
        self.urls = urls
        self.onDismiss = onDismiss
    }

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: urls, applicationActivities: nil)
        vc.completionWithItemsHandler = { _, _, _, _ in onDismiss() }
        return vc
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
