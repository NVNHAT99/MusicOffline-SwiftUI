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
                        .foregroundColor(.primaryText)
                }
            }
            .overlay(alignment: .bottom) {
                if let msg = viewModel.state.errorMessage {
                    Text(msg)
                        .font(AppFont.callout())
                        .foregroundColor(.primaryText)
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
                .foregroundColor(.accentPrimary)
            VStack(alignment: .leading, spacing: 4) {
                Text("Paste a direct audio link")
                    .font(AppFont.headline())
                    .foregroundColor(.primaryText)
                Text("HTTPS only. MP3, M4A, WAV, FLAC, AAC, OGG — up to 200 MB.")
                    .font(AppFont.callout())
                    .foregroundColor(.secondaryText)
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
        .foregroundColor(.primaryText)
        .font(AppFont.body())
    }

    private var startButton: some View {
        Button {
            viewModel.send(.start)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.down.circle.fill")
                Text("Download").bold()
            }
            .foregroundColor(.primaryText)
            .font(AppFont.headline())
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Capsule().fill(viewModel.state.canStart ? Color.accentPrimary : Color.mutedText))
        }
        .disabled(!viewModel.state.canStart)
        .buttonStyle(.pressScale)
    }

    private var progressBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            ProgressView(value: viewModel.state.progress)
                .progressViewStyle(.linear)
                .tint(Color.accentPrimary)
            HStack {
                Text("Downloading… \(Int(viewModel.state.progress * 100))%")
                    .font(AppFont.caption())
                    .foregroundColor(.secondaryText)
                Spacer()
                Button("Cancel") { viewModel.send(.cancel) }
                    .font(AppFont.caption())
                    .foregroundColor(.red)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
    }

    private func successBlock(name: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Saved to Library")
                    .font(AppFont.callout())
                    .foregroundColor(.primaryText)
            }
            Text(name)
                .font(AppFont.caption())
                .foregroundColor(.secondaryText)
            Button("Download another") { viewModel.send(.clear) }
                .font(AppFont.caption())
                .foregroundColor(.accentPrimary)
                .buttonStyle(.pressScale)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.green.opacity(0.12)))
    }

    private var notesBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Tips")
                .font(AppFont.caption())
                .fontWeight(.bold)
                .foregroundColor(.secondaryText)
            Text("• Google Drive *share* links don't work — they redirect to an HTML page. Use a direct file link or download via Drive app + import.")
            Text("• Dropbox links: replace dl=0 with dl=1 in the URL.")
            Text("• HTTPS links only — some archive.org links are HTTP and won't work. Use the https:// variant of the link.")
        }
        .font(AppFont.caption())
        .foregroundColor(.mutedText)
    }
}
