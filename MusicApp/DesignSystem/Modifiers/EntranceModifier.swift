import SwiftUI

// MARK: - Entrance
// Staggered appear animation for list rows / cards: each item fades + slides up,
// delayed by its index so a list cascades in. Under Reduce Motion it collapses
// to a plain fade with no offset and no per-item delay.

struct EntranceModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let index: Int
    var offset: CGFloat = 16
    var perItemDelay: Double = 0.04
    /// Cap so very long lists don't accumulate a multi-second delay.
    var maxDelayedItems: Int = 12

    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: reduceMotion ? 0 : (appeared ? 0 : offset))
            .onAppear {
                guard !appeared else { return }
                let cappedIndex = min(index, maxDelayedItems)
                let delay = reduceMotion ? 0 : Double(cappedIndex) * perItemDelay
                withAnimation(MotionToken.springStandard.delay(delay)) {
                    appeared = true
                }
            }
    }
}

extension View {
    /// Staggered entrance for the item at `index` in a list/grid.
    func entrance(index: Int = 0) -> some View {
        modifier(EntranceModifier(index: index))
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 12) {
            ForEach(0..<10) { i in
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentPrimary.opacity(0.4))
                    .frame(height: 60)
                    .overlay(Text("Row \(i)").foregroundStyle(.white))
                    .entrance(index: i)
            }
        }
        .padding()
    }
    .background(Color.backgroundColor)
}
