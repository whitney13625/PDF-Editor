import SwiftUI

struct ThumbnailGridView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var env: AppEnvironment
    @StateObject private var viewModel: ThumbnailGridViewModel

    let documentURL: URL

    private let columns = [GridItem(.adaptive(minimum: 120, maximum: 180), spacing: 12)]

    init(documentURL: URL) {
        self.documentURL = documentURL
        // StateObject init requires wrappedValue at init time;
        // actual dependencies injected via onAppear after env is available.
        _viewModel = StateObject(wrappedValue: ThumbnailGridViewModel(
            processor: PDFProcessingActor(),
            docManager: PDFDocumentManager(),
            history: CommandHistory()
        ))
    }

    var body: some View {
        content
            .navigationTitle("Pages (\(viewModel.pages.count))")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("Merge") { coordinator.openMerge() }
                    Button("Split") { coordinator.openSplit() }
                    Button("Export") {
                        Task {
                            if let doc = viewModel.currentDocument(),
                               let url = try? env.documentManager.writeToTemp(doc) {
                                coordinator.openExport(url: url)
                            }
                        }
                    }
                }
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button("Undo") { env.commandHistory.undo() }
                        .disabled(!env.commandHistory.canUndo)
                    Button("Redo") { env.commandHistory.redo() }
                        .disabled(!env.commandHistory.canRedo)
                }
            }
            .task { await viewModel.loadDocument(url: documentURL) }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView("Loading…")
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.pages) { page in
                        ThumbnailCell(page: page)
                            .contextMenu {
                                PageContextMenu(vm: viewModel, pageIndex: page.pageIndex)
                            }
                    }
                }
                .padding()
            }
        }
    }
}
