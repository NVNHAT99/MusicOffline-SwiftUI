import SwiftUI

// MARK: - NowPlayingFullPlayerView
struct NowPlayingFullPlayerView<ViewModel: NowPlayingViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    let uiImage: UIImage?
    @Binding var isExpanded: Bool
    @EnvironmentObject var router: Router<AppRoute>
    @Environment(\.appColorTheme) private var theme

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack {
                    navigationBar
                    Spacer().frame(height: DesignToken.Spacing.md)
                    FullPlayerArtworkView(
                        uiImage: uiImage,
                        showLyrics: viewModel.state.showLyrics,
                        lyrics: viewModel.state.lyrics,
                        activeLyricIndex: viewModel.activeLyricIndex,
                        geometry: geometry
                    )
                    Spacer().frame(height: 44)
                    controls(geometry: geometry)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, Helper.shared.safeAreaInsets?.top)
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
        .safeAreaInset(edge: .bottom) {
            // Bottom banner ad (full player, expanded state only).
            // Standard height here — MREC would crowd the player controls.
            AdBanner(size: .standard)
                .padding(.bottom, Helper.shared.safeAreaInsets?.bottom)
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
        return viewModel.state.showLyrics ? theme.accent : theme.onSurfaceSecondary
    }

    // MARK: - Controls
    private func controls(geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading) {
            songInfo
            Spacer().frame(height: DesignToken.Spacing.xl)
            FullPlayerProgressView(viewModel: viewModel)
            Spacer().frame(height: DesignToken.Spacing.lg)
            FullPlayerControlsView(viewModel: viewModel)
        }
        .frame(maxWidth: .infinity)
        // Use a fixed inset rather than width/10 — at small geometry widths
        // (e.g. when nested inside the MainTabView ZStack overlay) the
        // proportional inset collapses to near-zero and the controls
        // visibly clip the left edge.
        .padding(.horizontal, 28)
    }

    private var songInfo: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 4) {
                Text(viewModel.songTitle)
                    .font(AppFont.songTitle())
                    .foregroundStyle(theme.onSurface)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(viewModel.artistName)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(theme.onSurfaceSecondary)
                    .font(AppFont.callout())
            }
            lyricsToggleButton
            FullPlayerLyricsMenu(viewModel: viewModel)
        }
    }
}
