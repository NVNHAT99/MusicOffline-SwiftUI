import SwiftUI

// MARK: - FullPlayerLyricsMenu
// Ellipsis menu for managing lyrics (attach file / paste / remove) plus the
// Edit-Audio entry. Extracted from NowPlayingFullPlayerView to keep it under the
// size limit; routes audio-editor navigation through the injected router.

struct FullPlayerLyricsMenu<ViewModel: NowPlayingViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    @EnvironmentObject var router: Router<AppRoute>
    @Environment(\.appColorTheme) private var theme

    private var hasLyrics: Bool { !viewModel.state.lyrics.isEmpty }

    private var canOpenAudioEditor: Bool {
        guard let urlStr = viewModel.state.currentSong?.urlStr, !urlStr.isEmpty else { return false }
        return true
    }

    var body: some View {
        Menu {
            Button {
                viewModel.send(.presentLyricsPicker(true))
            } label: {
                Label("Attach Lyrics File…", systemImage: "doc.badge.plus")
            }
            Button {
                viewModel.send(.presentPasteLyricsSheet(true))
            } label: {
                Label("Paste Lyrics…", systemImage: "doc.on.clipboard")
            }
            Divider()
            Button {
                openAudioEditor()
            } label: {
                Label("Edit Audio…", systemImage: "scissors")
            }
            .disabled(!canOpenAudioEditor)
            if hasLyrics {
                Divider()
                Button(role: .destructive) {
                    viewModel.send(.removeLyrics)
                } label: {
                    Label("Remove Lyrics", systemImage: "trash")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .resizable()
                .scaledToFit()
                .frame(width: DesignToken.IconSize.md)
                .foregroundStyle(theme.onSurface.opacity(0.8))
        }
    }

    private func openAudioEditor() {
        guard let song = viewModel.state.currentSong,
              let urlStr = song.urlStr, !urlStr.isEmpty else { return }
        let url: URL = urlStr.hasPrefix("file://")
            ? (URL(string: urlStr) ?? URL(fileURLWithPath: urlStr))
            : URL(fileURLWithPath: urlStr)
        let title = song.title ?? url.deletingPathExtension().lastPathComponent
        router.route(to: .audioEditor(sourceURL: url, title: title))
    }
}
