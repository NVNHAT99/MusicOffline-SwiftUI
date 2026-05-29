import SwiftUI

// MARK: - NowPlayingMiniPlayerView
struct NowPlayingMiniPlayerView<ViewModel: NowPlayingViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    let uiImage: UIImage?
    let cornerRadius: CGFloat
    @Binding var isExpanded: Bool
    @Environment(\.appColorTheme) private var theme

    var body: some View {
        HStack(spacing: 12) {
            artwork
            songInfo
            Spacer()
            playButton
        }
        .padding(.horizontal, DesignToken.Spacing.md)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                // Tint the bar with the song's surface color so the mini player
                // echoes the artwork; kept dark for control legibility.
                .fill(theme.surface.opacity(0.92))
                .shadow(color: .black.opacity(0.3), radius: DesignToken.Shadow.medium, x: 0, y: -5)
        )
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(theme.accent)
                .frame(height: 2)
                .opacity(0.9)
                .padding(.horizontal, DesignToken.Spacing.md)
        }
        .onTapGesture { withAnimation(MotionToken.springStandard) { isExpanded = true } }
        .haptic(.impactLight, trigger: isExpanded)
        .gesture(
            DragGesture().onEnded { gesture in
                if gesture.translation.height < -50 {
                    withAnimation(MotionToken.springStandard) { isExpanded = true }
                }
            }
        )
    }

    // MARK: - Subviews
    private var artwork: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: DesignToken.Radius.sm))
            } else {
                RoundedRectangle(cornerRadius: DesignToken.Radius.sm)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .shimmer()
            }
        }
    }

    private var songInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(viewModel.songTitle)
                .font(AppFont.miniSongTitle())
                .foregroundColor(theme.onSurface)
                .lineLimit(1)
            Text(viewModel.artistName)
                .font(AppFont.callout())
                .foregroundColor(theme.onSurfaceSecondary)
                .lineLimit(1)
        }
    }

    private var playButton: some View {
        Button { viewModel.send(.togglePlay) } label: {
            Image(systemName: viewModel.playButtonIcon)
                .font(.system(size: DesignToken.IconSize.md))
                .foregroundColor(theme.accent)
        }
        .buttonStyle(.pressScale)
    }
}
