import SwiftUI

/// Scrolling lyrics panel with auto-scroll and active-line highlight.
/// Auto-scroll pauses for 3 seconds after the user manually scrolls.
struct LyricsView: View {

    let lines: [LyricsLine]
    let activeIndex: Int?

    @State private var userScrolling = false
    @State private var pauseScrollTask: Task<Void, Never>? = nil

    var body: some View {
        Group {
            if lines.isEmpty {
                Text("No lyrics available")
                    .font(AppFont.callout())
                    .foregroundColor(.mutedText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(Array(lines.enumerated()), id: \.offset) { idx, line in
                                Text(line.text)
                                    .font(idx == activeIndex ? AppFont.songTitle() : AppFont.callout())
                                    .foregroundColor(idx == activeIndex ? .primaryText : .mutedText)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                                    .animation(.easeInOut(duration: 0.2), value: activeIndex)
                                    .id(idx)
                            }
                        }
                        .padding(.vertical, 40)
                        .padding(.horizontal, 16)
                    }
                    .simultaneousGesture(
                        DragGesture().onChanged { _ in
                            pauseAutoScroll()
                        }
                    )
                    .onChange(of: activeIndex) { _, newIndex in
                        guard !userScrolling, let idx = newIndex else { return }
                        withAnimation(.easeInOut(duration: 0.4)) {
                            proxy.scrollTo(idx, anchor: .center)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Intentional: keep opaque dark background so lyrics stay readable over any player gradient.
        .background(Color.backgroundColor)
    }

    private func pauseAutoScroll() {
        userScrolling = true
        pauseScrollTask?.cancel()
        pauseScrollTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run { userScrolling = false }
        }
    }
}
