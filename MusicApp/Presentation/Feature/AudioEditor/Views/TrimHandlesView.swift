import SwiftUI

/// Two-handle trim overlay rendered on top of a waveform. Reports drag updates
/// as seconds via callbacks; clamping (min 1s apart, within duration) is the
/// reducer's responsibility — this view just translates pixels → seconds.
struct TrimHandlesView: View {

    let trimStart: Double
    let trimEnd: Double
    let duration: Double
    let onStartChange: (Double) -> Void
    let onEndChange: (Double) -> Void

    private let handleWidth: CGFloat = 14

    var body: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width
            let secondsPerPoint = duration > 0 ? duration / Double(totalWidth) : 0
            let startX = position(for: trimStart, width: totalWidth)
            let endX   = position(for: trimEnd,   width: totalWidth)

            ZStack(alignment: .topLeading) {
                // Dim outside [start, end].
                Rectangle()
                    .fill(Color.black.opacity(0.55))
                    .frame(width: startX, height: geo.size.height)
                Rectangle()
                    .fill(Color.black.opacity(0.55))
                    .frame(width: max(0, totalWidth - endX), height: geo.size.height)
                    .offset(x: endX)

                // Selection border
                Rectangle()
                    .stroke(Color.cyan, lineWidth: 2)
                    .frame(width: max(0, endX - startX), height: geo.size.height)
                    .offset(x: startX)

                handle(at: startX) { delta in
                    onStartChange(trimStart + delta * secondsPerPoint)
                }
                handle(at: endX) { delta in
                    onEndChange(trimEnd + delta * secondsPerPoint)
                }
            }
        }
    }

    private func handle(at x: CGFloat, onDelta: @escaping (Double) -> Void) -> some View {
        Rectangle()
            .fill(Color.cyan)
            .frame(width: handleWidth, height: nil)
            .overlay(
                Image(systemName: "line.3.horizontal")
                    .rotationEffect(.degrees(90))
                    .font(.system(size: 10))
                    .foregroundStyle(.white)
            )
            .offset(x: x - handleWidth / 2)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        onDelta(Double(value.translation.width))
                    }
            )
    }

    private func position(for time: Double, width: CGFloat) -> CGFloat {
        guard duration > 0 else { return 0 }
        return CGFloat(time / duration) * width
    }
}
