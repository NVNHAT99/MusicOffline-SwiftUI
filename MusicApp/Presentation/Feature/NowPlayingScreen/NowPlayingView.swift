import SwiftUI
import UIKit

// MARK: - NowPlayingView
// Coordinator view — delegates rendering to mini/full player subviews
struct NowPlayingView<ViewModel: NowPlayingViewModelProtocol>: View {
    @Binding var isExpanded: Bool
    @StateObject var viewModel: ViewModel
    @EnvironmentObject var router: Router<AppRoute>

    private let miniPlayerHeight: CGFloat = DesignToken.Player.miniPlayerHeight
    private let cornerRadius: CGFloat = DesignToken.Radius.md
    private let cache = ImageCacheFactory.createDefaultCache()
    @State private var uiImage: UIImage?

    init(isExpanded: Binding<Bool>, viewModel: ViewModel) {
        self._isExpanded = isExpanded
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack {
            Spacer()
            if !isExpanded {
                NowPlayingMiniPlayerView(
                    viewModel: viewModel,
                    uiImage: uiImage,
                    cornerRadius: cornerRadius,
                    isExpanded: $isExpanded
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                NowPlayingFullPlayerView(
                    viewModel: viewModel,
                    uiImage: uiImage,
                    isExpanded: $isExpanded
                )
                .environmentObject(router)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(Color.backgroundColor)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isExpanded)
        .task { await loadArtwork() }
        .onChange(of: viewModel.state.currentSong) { _, _ in
            Task { await loadArtwork() }
        }
    }

    // MARK: - Artwork Loading
    private func loadArtwork() async {
        guard let currentSong = viewModel.state.currentSong,
              let urlStr = try? currentSong.fileURLString(),
              let data = await cache.get(for: urlStr),
              let image = UIImage(data: data) else {
            uiImage = UIImage(named: "demoThumbnail2")
            return
        }
        uiImage = image
    }
}

// MARK: - Preview
#Preview {
    let container = DIContainer.preview
    NowPlayingView(isExpanded: .constant(true), viewModel: container.makeNowPlayingViewModel())
        .environmentObject(container)
        .environmentObject(Router<AppRoute>())
}
