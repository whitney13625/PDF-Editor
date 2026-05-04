import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var env: AppEnvironment
    @State private var loadedDocumentURL: URL?

    var body: some View {
        NavigationStack {
            Group {
                if let url = loadedDocumentURL {
                    ThumbnailGridView(
                        documentURL: url,
                        processor: env.pdfProcessor,
                        docManager: env.documentManager,
                        history: env.commandHistory
                    )
                } else {
                    EmptyStateView(
                        systemImage: "doc.fill",
                        title: "No Document",
                        message: "Import a PDF to get started",
                        actionTitle: "Import PDF"
                    ) {
                        coordinator.openDocumentPicker()
                    }
                    .navigationTitle("PDF Editor")
                }
            }
        }
        .sheet(item: $coordinator.activeSheet) { sheet in
            sheetContent(for: sheet)
        }
    }

    @ViewBuilder
    private func sheetContent(for sheet: AppSheet) -> some View {
        switch sheet {
        case .documentPicker:
            DocumentPickerView(allowsMultipleSelection: false) { urls in
                loadedDocumentURL = urls.first
                coordinator.dismiss()
            }
        case .export(let url):
            ExportView(url: url) { coordinator.dismiss() }
        case .saveToFiles(let url):
            SaveToFilesView(url: url) { coordinator.dismiss() }
        case .merge:
            MergeView(processor: env.pdfProcessor, docManager: env.documentManager)
        case .split(let url):
            SplitView(documentURL: url, processor: env.pdfProcessor, docManager: env.documentManager)
        }
    }
}
