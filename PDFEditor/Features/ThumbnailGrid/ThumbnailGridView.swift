import SwiftUI

struct ThumbnailGridView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var env: AppEnvironment
    @StateObject private var viewModel: ThumbnailGridViewModel

    private let columns = [GridItem(.adaptive(minimum: 120, maximum: 180), spacing: 12)]

    init(documentURL: URL, processor: PDFProcessingActor, docManager: PDFDocumentManager, history: CommandHistory) {
        _viewModel = StateObject(wrappedValue: ThumbnailGridViewModel(
            processor: processor,
            docManager: docManager,
            history: history
        ))
        self._documentURL = State(initialValue: documentURL)
    }

    @State private var documentURL: URL

    var body: some View {
        content
            .navigationTitle("Pages (\(viewModel.pages.count))")
            .toolbar { toolbar }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .task { await viewModel.loadDocument(url: documentURL) }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView("Loading…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.pages.isEmpty {
            EmptyStateView(
                systemImage: "doc.text",
                title: "Empty Document",
                message: "This PDF has no pages",
                actionTitle: "Import Another"
            ) { coordinator.openDocumentPicker() }
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

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarLeading) {
            Button {
                env.commandHistory.undo()
            } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            .disabled(!env.commandHistory.canUndo)

            Button {
                env.commandHistory.redo()
            } label: {
                Image(systemName: "arrow.uturn.forward")
            }
            .disabled(!env.commandHistory.canRedo)
        }

        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button("Merge") { coordinator.openMerge() }
            Button("Split") { coordinator.openSplit() }
            Button {
                Task {
                    if let doc = viewModel.currentDocument(),
                       let url = try? env.documentManager.writeToTemp(doc) {
                        coordinator.openExport(url: url)
                    }
                }
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
        }
    }
}
