import SwiftUI

// MARK: - NowPlayingFullPlayerView
struct NowPlayingFullPlayerView<ViewModel: NowPlayingViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    let uiImage: UIImage?
    @Binding var isExpanded: Bool
    @EnvironmentObject var router: Router<AppRoute>

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack {
                    navigationBar
                    Spacer().frame(height: DesignToken.Spacing.md)
                    artwork(geometry: geometry)
                    Spacer().frame(height: 44)
                    controls(geometry: geometry)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, Helper.shared.safeAreaInsets?.top)
                .background(Color.backgroundColor)
                .gesture(
                    DragGesture().onEnded { gesture in
                        if gesture.translation.height > 100 {
                            withAnimation { isExpanded = false }
                        }
                    }
                )
            }
            .scrollIndicators(.hidden)
        }
        .overlay(alignment: .bottom) {
            if let errorMsg = viewModel.state.errorMessage ?? viewModel.state.lyricsErrorMessage {
                Text(errorMsg)
                    .font(AppFont.callout())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.red.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut, value: viewModel.state.errorMessage)
                    .animation(.easeInOut, value: viewModel.state.lyricsErrorMessage)
            }
        }
        .sheet(isPresented: pasteLyricsBinding) {
            PasteLyricsSheetView(
                onSave: { viewModel.send(.pasteLyrics($0)) },
                onCancel: { viewModel.send(.presentPasteLyricsSheet(false)) }
            )
        }
        .sheet(isPresented: lyricsPickerBinding) {
            LyricsFilePickerView { url in
                viewModel.send(.presentLyricsPicker(false))
                if let url = url {
                    viewModel.send(.attachLyricsFile(url))
                }
            }
        }
    }

    // MARK: - Sheet Bindings

    private var pasteLyricsBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.showPasteLyricsSheet },
            set: { if !$0 { viewModel.send(.presentPasteLyricsSheet(false)) } }
        )
    }

    private var lyricsPickerBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.showLyricsPicker },
            set: { if !$0 { viewModel.send(.presentLyricsPicker(false)) } }
        )
    }

    // MARK: - Navigation Bar
    private var navigationBar: some View {
        CustomNavigationBar(type: .custom(
            title: "",
            left: .init(icon: "chevron.down", action: { withAnimation { isExpanded = false } }),
            right: .init(icon: "gearshape.fill", action: { router.route(to: .timerMenuSheet) })
        ))
    }

    // MARK: - Lyrics Toggle Button
    private var hasLyrics: Bool { !viewModel.state.lyrics.isEmpty }

    private var lyricsToggleButton: some View {
        Button {
            viewModel.send(.toggleLyrics)
        } label: {
            Image(systemName: "text.quote")
                .resizable()
                .scaledToFit()
                .frame(width: DesignToken.IconSize.md)
                .foregroundStyle(lyricsToggleColor)
        }
        .disabled(!hasLyrics)
    }

    private var lyricsToggleColor: Color {
        if !hasLyrics { return Color.gray.opacity(0.35) }
        return viewModel.state.showLyrics ? .white : .gray
    }

    // MARK: - Audio Editor entry

    private var canOpenAudioEditor: Bool {
        guard let urlStr = viewModel.state.currentSong?.urlStr, !urlStr.isEmpty else { return false }
        return true
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

    /// Ellipsis menu for managing lyrics (attach file / paste text / remove).
    private var lyricsMenuButton: some View {
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
                .foregroundStyle(Color.white.opacity(0.8))
        }
    }

    // MARK: - Artwork / Lyrics Panel
    private func artwork(geometry: GeometryProxy) -> some View {
        let size = geometry.size.height * 3 / 5
        return Group {
            if viewModel.state.showLyrics {
                LyricsView(
                    lines: viewModel.state.lyrics,
                    activeIndex: viewModel.state.activeLyricIndex
                )
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: DesignToken.Radius.sm))
            } else if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: DesignToken.Radius.sm))
                    .shadow(color: .black.opacity(0.3), radius: DesignToken.Shadow.large, x: 0, y: 10)
            } else {
                RoundedRectangle(cornerRadius: DesignToken.Radius.sm)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: size, height: size)
                    .shimmer()
            }
        }
    }

    // MARK: - Controls
    private func controls(geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading) {
            songInfo
            Spacer().frame(height: DesignToken.Spacing.xl)
            progressSection
            Spacer().frame(height: DesignToken.Spacing.lg)
            playbackButtons
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, geometry.size.width / 10)
    }

    private var songInfo: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 4) {
                Text(viewModel.songTitle)
                    .font(AppFont.songTitle())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(viewModel.artistName)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(.white)
                    .font(AppFont.callout())
            }
            lyricsToggleButton
            lyricsMenuButton
        }
    }

    private var progressSection: some View {
        VStack {
            CustomSliderView(
                value: $viewModel.state.currentTime,
                isDragSliderView: $viewModel.state.isDraging,
                minValue: 0,
                maxValue: viewModel.state.duration,
                trackColor: Color(hexString: "#808080"),
                progressColor: .white
            ) { value in
                viewModel.send(.seekTo(value))
            }
            .frame(height: 12)

            HStack {
                Text(viewModel.currentTimeStr).foregroundStyle(.white)
                Spacer()
                Text(viewModel.state.duration.toTimeString()).foregroundStyle(.white)
            }
            .font(AppFont.timeLabel())
        }
    }

    private var playbackButtons: some View {
        HStack {
            Button { viewModel.send(.changeShuffMode) } label: {
                Image(systemName: "shuffle")
                    .resizable().scaledToFit().aspectRatio(1, contentMode: .fit)
                    .foregroundStyle(viewModel.shuffleButtonColor)
                    .frame(width: DesignToken.IconSize.md)
            }
            Spacer()
            Button { viewModel.send(.goPrevious) } label: {
                Image(systemName: "arrowtriangle.backward.fill")
                    .resizable().scaledToFit().aspectRatio(1, contentMode: .fit)
                    .foregroundStyle(.white)
                    .frame(width: DesignToken.Player.controlButtonSize)
            }
            Spacer()
            Button { viewModel.send(.togglePlay) } label: {
                Image(systemName: viewModel.playButtonIcon)
                    .resizable().scaledToFit().aspectRatio(1, contentMode: .fit)
                    .foregroundStyle(.white)
                    .frame(width: DesignToken.Player.playButtonSize)
            }
            Spacer()
            Button { viewModel.send(.goNext) } label: {
                Image(systemName: "arrowtriangle.right.fill")
                    .resizable().scaledToFit().aspectRatio(1, contentMode: .fit)
                    .foregroundStyle(.white)
                    .frame(width: DesignToken.Player.controlButtonSize)
            }
            Spacer()
            Button { viewModel.send(.changeRepeatMode) } label: {
                Image(systemName: viewModel.repeatButtonIcon)
                    .resizable().scaledToFit().aspectRatio(1, contentMode: .fit)
                    .foregroundStyle(viewModel.repeatButtonColor)
                    .frame(width: DesignToken.IconSize.md)
            }
        }
    }
}
