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
    private let cache = ImageCacheFactory.shared
    @State private var uiImage: UIImage?
    /// Per-song color theme derived from artwork. `.default` until extraction
    /// completes (or when there's no artwork), preserving the original look.
    @State private var theme: AppColorTheme = .default

    init(isExpanded: Binding<Bool>, viewModel: ViewModel) {
        self._isExpanded = isExpanded
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if !isExpanded {
                // Mini bar wants to size to its own content, not push to bottom
                // — its parent (MainTabView) positions it above the tab bar.
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
                .dynamicBackground()
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .appColorTheme(theme)
        .animation(MotionToken.springStandard, value: isExpanded)
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
            theme = .default
            return
        }
        uiImage = image
        // Derive the per-song color theme. Cached per URL by PaletteProvider, so
        // a revisit doesn't recompute; runs off the main thread.
        let palette = await PaletteProvider.shared.palette(forKey: urlStr, image: image)
        theme = .dynamic(from: palette)
    }
}

// MARK: - Preview
#Preview {
    let container = DIContainer.preview
    NowPlayingView(isExpanded: .constant(true), viewModel: container.makeNowPlayingViewModel())
        .environmentObject(container)
        .environmentObject(Router<AppRoute>())
}
