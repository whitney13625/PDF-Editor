import SwiftUI
import UniformTypeIdentifiers

// Presents UIDocumentPickerViewController in export mode so the user can save
// a PDF to a chosen location in the Files app. The source temp file is cleaned
// up after the picker completes (whether the user saves or cancels).
struct SaveToFilesView: UIViewControllerRepresentable {
    let url: URL
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forExporting: [url], asCopy: true)
        picker.delegate = context.coordinator
        picker.shouldShowFileExtensions = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(url: url, onDismiss: onDismiss) }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        private let url: URL
        private let onDismiss: () -> Void

        init(url: URL, onDismiss: @escaping () -> Void) {
            self.url = url
            self.onDismiss = onDismiss
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            cleanupAndDismiss()
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            cleanupAndDismiss()
        }

        private func cleanupAndDismiss() {
            try? FileManager.default.removeItem(at: url)
            onDismiss()
        }
    }
}
