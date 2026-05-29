import SwiftUI

struct UrlDownloadView: View {

    @StateObject private var viewModel = UrlDownloadViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundColor.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header
                        urlField
                        if viewModel.state.isDownloading {
                            progressBlock
                        } else if let name = viewModel.state.completedFilename {
                            successBlock(name: name)
                        } else {
                            startButton
                        }
                        notesBlock
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Download from URL")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
            .overlay(alignment: .bottom) {
                if let msg = viewModel.state.errorMessage {
                    Text(msg)
                        .font(.callout)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.85))
                        .clipShape(Capsule())
                        .padding(.bottom, 24)
                        .onTapGesture { viewModel.send(.dismissError) }
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "link.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(.cyan)
            VStack(alignment: .leading, spacing: 4) {
                Text("Paste a direct audio link")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("HTTPS only. MP3, M4A, WAV, FLAC, AAC, OGG — up to 200 MB.")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
        }
    }

    private var urlField: some View {
        TextField("https://example.com/song.mp3", text: Binding(
            get: { viewModel.state.urlText },
            set: { viewModel.send(.setURL($0)) }
        ))
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .keyboardType(.URL)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.1)))
        .foregroundStyle(.white)
    }

    private var startButton: some View {
        Button {
            viewModel.send(.start)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.down.circle.fill")
                Text("Download").bold()
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Capsule().fill(viewModel.state.canStart ? Color.cyan : Color.gray))
        }
        .disabled(!viewModel.state.canStart)
    }

    private var progressBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            ProgressView(value: viewModel.state.progress)
                .progressViewStyle(.linear)
                .tint(.cyan)
            HStack {
                Text("Downloading… \(Int(viewModel.state.progress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Button("Cancel") { viewModel.send(.cancel) }
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
    }

    private func successBlock(name: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Saved to Library")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
            }
            Text(name)
                .font(.caption)
                .foregroundStyle(.gray)
            Button("Download another") { viewModel.send(.clear) }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.cyan)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.green.opacity(0.12)))
    }

    private var notesBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Tips")
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.7))
            Text("• Google Drive *share* links don't work — they redirect to an HTML page. Use a direct file link or download via Drive app + import.")
            Text("• Dropbox links: replace dl=0 with dl=1 in the URL.")
            Text("• HTTPS links only — some archive.org links are HTTP and won't work. Use the https:// variant of the link.")
        }
        .font(.caption)
        .foregroundStyle(.gray)
    }
}
