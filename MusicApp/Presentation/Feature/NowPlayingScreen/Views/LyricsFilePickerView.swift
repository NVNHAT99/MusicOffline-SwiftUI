import SwiftUI
import UniformTypeIdentifiers

/// Document picker scoped to lyrics formats (.lrc, .txt) so the user
/// doesn't see audio files when they explicitly want to attach lyrics.
struct LyricsFilePickerView: UIViewControllerRepresentable {

    let onPick: (URL?) -> Void

    private static let supportedTypes: [UTType] = [
        UTType(filenameExtension: "lrc") ?? .plainText,
        .plainText,
        .text
    ]

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: Self.supportedTypes, asCopy: true)
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL?) -> Void
        init(onPick: @escaping (URL?) -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onPick(urls.first)
        }
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onPick(nil)
        }
    }
}
