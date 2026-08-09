import SwiftUI

// MARK: - FullPlayerControlsView
// Transport row for the full player: shuffle · previous · play/pause · next ·
// repeat. Buttons use press-scale + haptics; shuffle/repeat tint with the active
// theme accent when enabled. Extracted to keep the full player under the limit.

struct FullPlayerControlsView<ViewModel: NowPlayingViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    @Environment(\.appColorTheme) private var theme

    var body: some View {
        HStack {
            Button { viewModel.send(.changeShuffMode) } label: {
                icon("shuffle", size: DesignToken.IconSize.md, color: toggleColor(viewModel.shuffleButtonColor))
            }
            .buttonStyle(.pressScale)
            Spacer()
            Button { viewModel.send(.goPrevious) } label: {
                icon("backward.fill", size: DesignToken.Player.controlButtonSize, color: theme.onSurface)
            }
            .buttonStyle(.pressScale)
            Spacer()
            Button { viewModel.send(.togglePlay) } label: {
                icon(viewModel.playButtonIcon, size: DesignToken.Player.playButtonSize, color: theme.onSurface)
            }
            .buttonStyle(.pressScale(scale: 0.9))
            Spacer()
            Button { viewModel.send(.goNext) } label: {
                icon("forward.fill", size: DesignToken.Player.controlButtonSize, color: theme.onSurface)
            }
            .buttonStyle(.pressScale)
            Spacer()
            Button { viewModel.send(.changeRepeatMode) } label: {
                icon(viewModel.repeatButtonIcon, size: DesignToken.IconSize.md, color: toggleColor(viewModel.repeatButtonColor))
            }
            .buttonStyle(.pressScale)
        }
    }

    /// When a toggle's own color logic says "active" (white), use the theme
    /// accent instead so it reads as colorful; otherwise keep its dimmed color.
    private func toggleColor(_ original: Color) -> Color {
        original == .white ? theme.accent : original
    }

    private func icon(_ name: String, size: CGFloat, color: Color) -> some View {
        Image(systemName: name)
            .resizable()
            .scaledToFit()
            .aspectRatio(1, contentMode: .fit)
            .foregroundStyle(color)
            .frame(width: size)
    }
}
