import SwiftUI

// MARK: - FullPlayerProgressView
// Scrubber + elapsed/remaining time for the full player. The progress fill uses
// the per-song accent from the active theme so it tints with the artwork.

struct FullPlayerProgressView<ViewModel: NowPlayingViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    @Environment(\.appColorTheme) private var theme

    var body: some View {
        VStack {
            CustomSliderView(
                value: $viewModel.currentTime,
                isDragSliderView: $viewModel.isDragging,
                minValue: 0,
                maxValue: viewModel.state.duration,
                trackColor: Color.white.opacity(0.25),
                progressColor: theme.accent
            ) { value in
                viewModel.send(.seekTo(value))
            }
            .frame(height: 12)

            HStack {
                Text(viewModel.currentTimeStr)
                Spacer()
                Text(viewModel.state.duration.toTimeString())
            }
            .font(AppFont.timeLabel())
            .foregroundStyle(theme.onSurfaceSecondary)
        }
    }
}
