import SwiftUI

/// Renders pre-scanned per-bucket peaks as a symmetric vertical waveform.
/// Each bucket = 1 thin bar centered on the row's midline.
struct WaveformView: View {

    let samples: [Float]
    let barColor: Color

    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                guard !samples.isEmpty else { return }
                let count = samples.count
                let widthPerBar = size.width / CGFloat(count)
                let midY = size.height / 2
                for (i, peak) in samples.enumerated() {
                    let h = CGFloat(max(0.02, peak)) * size.height
                    let x = CGFloat(i) * widthPerBar
                    let rect = CGRect(
                        x: x + widthPerBar * 0.15,
                        y: midY - h / 2,
                        width: max(1, widthPerBar * 0.7),
                        height: h
                    )
                    ctx.fill(Path(rect), with: .color(barColor))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}
