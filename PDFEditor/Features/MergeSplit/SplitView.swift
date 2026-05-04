import SwiftUI

struct SplitView: View {
    @StateObject private var viewModel: SplitViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showShareSheet = false

    init(documentURL: URL, processor: PDFProcessingActor, docManager: PDFDocumentManager) {
        _viewModel = StateObject(wrappedValue: SplitViewModel(
            documentURL: documentURL,
            processor: processor,
            docManager: docManager
        ))
    }

    var body: some View {
        NavigationView {
            Group {
                if viewModel.pageCount < 2 {
                    cantSplitState
                } else {
                    splitControls
                }
            }
            .navigationTitle("Split PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .overlay { if viewModel.isProcessing { LoadingOverlay(message: "Splitting…") } }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .sheet(isPresented: $showShareSheet, onDismiss: { viewModel.resultURLs = [] }) {
                ExportView(urls: viewModel.resultURLs) { showShareSheet = false }
            }
            .onChange(of: viewModel.resultURLs) { urls in
                if !urls.isEmpty { showShareSheet = true }
            }
        }
    }

    // MARK: - Subviews

    private var cantSplitState: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("Cannot Split")
                .font(.headline)
            Text("The document needs at least 2 pages to split.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }

    private var splitControls: some View {
        VStack(spacing: 0) {
            // Document header
            VStack(spacing: 4) {
                Image(systemName: "doc.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.accentColor)
                Text(viewModel.documentName)
                    .font(.headline)
                    .lineLimit(1)
                Text("\(viewModel.pageCount) pages total")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 24)
            .padding(.bottom, 20)

            Divider()

            // Split point picker
            VStack(spacing: 12) {
                Text("Split after page")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("\(viewModel.splitPoint)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.accentColor)

                Slider(
                    value: Binding(
                        get: { Double(viewModel.splitPoint) },
                        set: { viewModel.splitPoint = Int($0) }
                    ),
                    in: viewModel.splitRange,
                    step: 1
                )
                .padding(.horizontal, 32)

                HStack {
                    Text("1")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(viewModel.pageCount - 1)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 32)
            }
            .padding(.vertical, 24)

            Divider()

            // Preview
            HStack(spacing: 0) {
                partPreview(
                    label: "Part 1",
                    pageRange: "Pages 1–\(viewModel.splitPoint)",
                    count: viewModel.part1Count
                )

                Divider().frame(height: 80)

                partPreview(
                    label: "Part 2",
                    pageRange: "Pages \(viewModel.splitPoint + 1)–\(viewModel.pageCount)",
                    count: viewModel.part2Count
                )
            }
            .padding(.vertical, 16)

            Divider()

            // Split button
            Button {
                Task { await viewModel.split() }
            } label: {
                Label("Split into 2 Files", systemImage: "scissors")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
            }
            .disabled(viewModel.isProcessing)

            Spacer()
        }
    }

    private func partPreview(label: String, pageRange: String, count: Int) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(pageRange)
                .font(.subheadline)
                .bold()
            Text("\(count) page\(count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
