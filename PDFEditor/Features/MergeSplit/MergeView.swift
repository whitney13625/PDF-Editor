import SwiftUI

struct MergeView: View {
    @StateObject private var viewModel: MergeViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showPicker = false
    @State private var showShareSheet = false

    init(processor: PDFProcessingActor, docManager: PDFDocumentManager) {
        _viewModel = StateObject(wrappedValue: MergeViewModel(
            processor: processor,
            docManager: docManager
        ))
    }

    var body: some View {
        NavigationView {
            List {
                if viewModel.items.isEmpty {
                    emptyState
                } else {
                    itemRows
                }
            }
            .navigationTitle("Merge PDFs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .overlay { if viewModel.isProcessing { LoadingOverlay(message: "Merging…") } }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .sheet(isPresented: $showPicker) {
                DocumentPickerView(allowsMultipleSelection: true) { urls in
                    viewModel.addDocuments(urls)
                    showPicker = false
                }
            }
            .sheet(item: $viewModel.resultURL) { url in
                ExportView(url: url) { viewModel.resultURL = nil }
            }
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.on.doc")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("No PDFs selected")
                .font(.headline)
            Text("Tap **Add PDF** to select files to merge")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .listRowBackground(Color.clear)
    }

    private var itemRows: some View {
        ForEach(viewModel.items) { item in
            HStack(spacing: 12) {
                Image(systemName: "doc.fill")
                    .foregroundColor(.accentColor)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .lineLimit(1)
                    Text("\(item.pageCount) page\(item.pageCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 2)
        }
        .onDelete(perform: viewModel.removeItems)
        .onMove(perform: viewModel.moveItem)
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            EditButton()
                .disabled(viewModel.items.isEmpty)
        }
        ToolbarItemGroup(placement: .bottomBar) {
            Button {
                showPicker = true
            } label: {
                Label("Add PDF", systemImage: "plus")
            }

            Spacer()

            Button {
                Task { await viewModel.merge() }
            } label: {
                Label("Merge", systemImage: "doc.on.doc.fill")
            }
            .disabled(viewModel.items.count < 2 || viewModel.isProcessing)
            .bold()
        }
    }
}

// Make URL Identifiable for .sheet(item:)
extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}
