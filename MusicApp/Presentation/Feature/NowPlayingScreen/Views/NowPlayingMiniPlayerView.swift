import SwiftUI

// MARK: - NowPlayingMiniPlayerView
struct NowPlayingMiniPlayerView<ViewModel: NowPlayingViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    let uiImage: UIImage?
    let cornerRadius: CGFloat
    @Binding var isExpanded: Bool

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
                .fill(Color.black.opacity(0.9))
                .shadow(color: .black.opacity(0.3), radius: DesignToken.Shadow.medium, x: 0, y: -5)
        )
        .onTapGesture { withAnimation { isExpanded = true } }
        .gesture(
            DragGesture().onEnded { gesture in
                if gesture.translation.height < -50 {
                    withAnimation { isExpanded = true }
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
                .foregroundColor(.white)
                .lineLimit(1)
            Text(viewModel.artistName)
                .font(AppFont.callout())
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(1)
        }
    }

    private var playButton: some View {
        Button { viewModel.send(.togglePlay) } label: {
            Image(systemName: viewModel.playButtonIcon)
                .font(.system(size: DesignToken.IconSize.md))
                .foregroundColor(.white)
        }
    }
}
