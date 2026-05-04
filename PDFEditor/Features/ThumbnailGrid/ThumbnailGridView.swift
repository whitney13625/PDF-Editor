import SwiftUI
import UniformTypeIdentifiers

struct ThumbnailGridView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var env: AppEnvironment
    @StateObject private var viewModel: ThumbnailGridViewModel

    @State private var draggingID: UUID?
    @State private var dragStartIndex: Int?

    @State private var documentURL: URL

    private let columns = [GridItem(.adaptive(minimum: 120, maximum: 180), spacing: 12)]

    init(documentURL: URL, processor: PDFProcessingActor, docManager: PDFDocumentManager, history: CommandHistory) {
        _viewModel = StateObject(wrappedValue: ThumbnailGridViewModel(
            processor: processor,
            docManager: docManager,
            history: history
        ))
        _documentURL = State(initialValue: documentURL)
    }

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

    // MARK: - Content

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
                            .opacity(draggingID == page.id ? 0.4 : 1.0)
                            .scaleEffect(draggingID == page.id ? 0.93 : 1.0)
                            .animation(.easeInOut(duration: 0.15), value: draggingID)
                            .contextMenu {
                                PageContextMenu(vm: viewModel, pageIndex: page.pageIndex)
                            }
                            .onDrag {
                                dragStartIndex = viewModel.pages.firstIndex(where: { $0.id == page.id })
                                draggingID = page.id
                                return NSItemProvider(object: page.id.uuidString as NSString)
                            }
                            .onDrop(
                                of: [UTType.plainText],
                                delegate: PageDropDelegate(
                                    targetPage: page,
                                    viewModel: viewModel,
                                    draggingID: $draggingID,
                                    dragStartIndex: $dragStartIndex
                                )
                            )
                    }
                }
                .padding()
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarLeading) {
            Button {
                env.commandHistory.undo()
                Task { await viewModel.reloadPages() }
            } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            .disabled(!env.commandHistory.canUndo)

            Button {
                env.commandHistory.redo()
                Task { await viewModel.reloadPages() }
            } label: {
                Image(systemName: "arrow.uturn.forward")
            }
            .disabled(!env.commandHistory.canRedo)
        }

        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button("Merge") { coordinator.openMerge() }
            Button("Split") {
                Task {
                    if let doc = viewModel.currentDocument(),
                       let url = try? env.documentManager.writeToTemp(
                           doc, name: "\(viewModel.documentName)_split_source"
                       ) {
                        coordinator.openSplit(url: url)
                    }
                }
            }
            exportMenu
        }
    }
}

// MARK: - Export helpers

extension ThumbnailGridView {
    private var exportMenu: some View {
        Menu {
            Button {
                Task { await shareDocument() }
            } label: {
                Label("Share…", systemImage: "square.and.arrow.up")
            }

            Button {
                Task { await saveToFiles() }
            } label: {
                Label("Save to Files…", systemImage: "folder")
            }
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
    }

    private func shareDocument() async {
        guard let doc = viewModel.currentDocument(),
              let url = try? env.documentManager.writeToTemp(
                  doc, name: "\(viewModel.documentName)_edited"
              ) else { return }
        coordinator.openExport(url: url)
    }

    private func saveToFiles() async {
        guard let doc = viewModel.currentDocument(),
              let url = try? env.documentManager.writeToTemp(
                  doc, name: "\(viewModel.documentName)_edited"
              ) else { return }
        coordinator.openSaveToFiles(url: url)
    }
}

// MARK: - PageDropDelegate

private struct PageDropDelegate: DropDelegate {
    let targetPage: PDFPageModel
    let viewModel: ThumbnailGridViewModel
    @Binding var draggingID: UUID?
    @Binding var dragStartIndex: Int?

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func dropEntered(info: DropInfo) {
        guard
            let id = draggingID,
            id != targetPage.id,
            let fromIndex = viewModel.pages.firstIndex(where: { $0.id == id }),
            let toIndex = viewModel.pages.firstIndex(where: { $0.id == targetPage.id })
        else { return }

        withAnimation(.easeInOut(duration: 0.2)) {
            viewModel.movePagePreview(
                from: IndexSet(integer: fromIndex),
                to: toIndex > fromIndex ? toIndex + 1 : toIndex
            )
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        if let startIndex = dragStartIndex, let id = draggingID {
            viewModel.commitDrag(startIndex: startIndex, draggingID: id)
        }
        draggingID = nil
        dragStartIndex = nil
        return true
    }
}
