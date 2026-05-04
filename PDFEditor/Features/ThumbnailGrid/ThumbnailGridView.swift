import SwiftUI

struct ThumbnailGridView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @EnvironmentObject private var env: AppEnvironment
    @State private var viewModel: ThumbnailGridViewModel?

    let documentURL: URL

    private let columns = [GridItem(.adaptive(minimum: 120, maximum: 180), spacing: 12)]

    var body: some View {
        Group {
            if let vm = viewModel {
                content(vm: vm)
            } else {
                ProgressView()
            }
        }
        .task {
            let vm = ThumbnailGridViewModel(
                processor: env.pdfProcessor,
                docManager: env.documentManager,
                history: env.commandHistory
            )
            viewModel = vm
            await vm.loadDocument(url: documentURL)
        }
    }

    @ViewBuilder
    private func content(vm: ThumbnailGridViewModel) -> some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(vm.pages) { page in
                    ThumbnailCell(page: page)
                        .contextMenu {
                            PageContextMenu(vm: vm, pageIndex: page.pageIndex)
                        }
                }
            }
            .padding()
        }
        .navigationTitle("Pages (\(vm.pages.count))")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button("Merge") { coordinator.openMerge() }
                Button("Split") { coordinator.openSplit() }
                Button("Export") {
                    Task {
                        if let doc = vm.currentDocument(),
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
    }
}
