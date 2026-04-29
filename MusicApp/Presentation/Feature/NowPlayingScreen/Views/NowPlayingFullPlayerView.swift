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
            if let errorMsg = viewModel.state.errorMessage {
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
            }
        }
    }

    // MARK: - Navigation Bar
    private var navigationBar: some View {
        CustomNavigationBar(type: .custom(
            title: "",
            left: .init(icon: "chevron.down", action: { withAnimation { isExpanded = false } }),
            right: .init(icon: "gearshape.fill", action: { router.route(to: .timerMenuSheet) })
        ))
    }

    // MARK: - Artwork
    private func artwork(geometry: GeometryProxy) -> some View {
        let size = geometry.size.height * 3 / 5
        return Group {
            if let uiImage {
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
