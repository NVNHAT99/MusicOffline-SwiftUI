//
//  ImportSongView.swift
//  MusicApp
//

import SwiftUI
import UniformTypeIdentifiers

/// UIDocumentPickerViewController wrapper for SwiftUI
struct DocumentPickerView: UIViewControllerRepresentable {
    let onPick: ([URL]) -> Void

    private static let supportedTypes: [UTType] = [
        .audio,
        UTType(filenameExtension: "flac") ?? .audio,
        UTType(filenameExtension: "ogg") ?? .audio,
        // .lrc lyrics — routed into LyricsRepository inside ImportSongFromFilesUseCase
        UTType(filenameExtension: "lrc") ?? .plainText,
        .plainText
    ]

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: Self.supportedTypes, asCopy: true)
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: ([URL]) -> Void
        init(onPick: @escaping ([URL]) -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onPick(urls)
        }
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {}
    }
}

struct ImportSongView<ViewModel: ImportSongViewModelProtocol>: View {

    @StateObject var viewModel: ViewModel
    @State private var showPicker = false

    init(viewModel: ViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                CloudImportGuideContent()

                if viewModel.state.isImporting {
                    progressView()
                } else {
                    importButton()
                }
            }
            .padding(20)
        }
        .sheet(isPresented: $showPicker) {
            DocumentPickerView { urls in
                showPicker = false
                viewModel.send(.importFiles(urls))
            }
        }
        .sheet(isPresented: Binding(
            get: { viewModel.state.isShowResults },
            set: { if !$0 { viewModel.send(.dismissResults) } }
        )) {
            resultsSheet()
        }
    }

    @ViewBuilder
    private func importButton() -> some View {
        Button(action: { showPicker = true }) {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.down")
                Text("Import from Files")
                    .font(AppFont.headline())
            }
            .foregroundColor(.primaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.accentPrimary)
            .cornerRadius(12)
        }
        .buttonStyle(.pressScale)
    }

    @ViewBuilder
    private func progressView() -> some View {
        VStack(spacing: 8) {
            ProgressView(value: Double(viewModel.state.progress), total: Double(max(viewModel.state.total, 1)))
                .progressViewStyle(.linear)
                .tint(Color.accentPrimary)
            Text("Importing \(viewModel.state.progress) / \(viewModel.state.total)")
                .foregroundColor(.secondaryText)
                .font(AppFont.caption())
        }
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private func resultsSheet() -> some View {
        NavigationView {
            List(viewModel.state.results, id: \.fileName) { result in
                HStack(spacing: 12) {
                    Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(result.success ? .green : .red)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(result.fileName)
                            .font(AppFont.callout())
                            .foregroundColor(.primary)
                        if let err = result.error {
                            Text(err.localizedDescription)
                                .font(AppFont.caption())
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Import Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { viewModel.send(.dismissResults) }
                }
            }
        }
    }
}
