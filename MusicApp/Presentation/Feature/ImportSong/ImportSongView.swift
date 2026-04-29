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
        UTType(filenameExtension: "ogg") ?? .audio
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
        VStack(spacing: 16) {
            if viewModel.state.isImporting {
                progressView()
            } else {
                importButton()
            }
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
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.gray.opacity(0.3))
            .cornerRadius(10)
        }
    }

    @ViewBuilder
    private func progressView() -> some View {
        VStack(spacing: 8) {
            ProgressView(value: Double(viewModel.state.progress), total: Double(max(viewModel.state.total, 1)))
                .progressViewStyle(.linear)
                .tint(.blue)
            Text("Importing \(viewModel.state.progress) / \(viewModel.state.total)")
                .foregroundColor(.white.opacity(0.7))
                .font(.caption)
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
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        if let err = result.error {
                            Text(err.localizedDescription)
                                .font(.caption)
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
