import SwiftUI

/// Sheet for pasting raw lyrics text (LRC-formatted or plain) and saving them
/// against the current song's stem. Plain-text paste is allowed because the LRC
/// parser tolerates lines without timestamps (they are simply ignored).
struct PasteLyricsSheetView: View {

    let onSave: (String) -> Void
    let onCancel: () -> Void

    @State private var text: String = ""

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Paste LRC-formatted lyrics. Lines without [mm:ss.xx] timestamps are skipped during playback.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 8)

                TextEditor(text: $text)
                    .font(.system(.body, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.bottom)
            }
            .navigationTitle("Paste Lyrics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave(text) }
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
