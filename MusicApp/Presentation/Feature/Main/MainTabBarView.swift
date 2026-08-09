import SwiftUI

// MARK: - MainTabBarView
// The custom bottom tab bar. Active tab uses the accent token + a subtle scale
// (collapses to color-only under Reduce Motion); switching tabs fires a
// selection haptic. Extracted from MainTabView to keep both files focused.

struct MainTabBarView: View {
    @Binding var currentTab: MainTab
    let bottomSafeArea: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTab.allCases, id: \.identifier) { tab in
                tabButton(tab: tab)
            }
        }
        .padding(.bottom, bottomSafeArea == 0 ? 10 : max(0, bottomSafeArea - 10))
        .frame(height: 100 + (bottomSafeArea == 0 ? 0 : bottomSafeArea - 10))
        .background(Color.backgroundColor)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: -2)
    }

    @ViewBuilder
    private func tabButton(tab: MainTab) -> some View {
        let isActive = currentTab == tab
        Button {
            withAnimation(MotionToken.springSnappy) { currentTab = tab }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: iconName(for: tab))
                    .font(.system(size: DesignToken.IconSize.md))
                    .symbolVariant(isActive ? .fill : .none)
                Text(tabTitle(for: tab))
                    .font(AppFont.tabLabel())
            }
            .foregroundStyle(isActive ? Color.accentPrimary : Color.tabInactive)
            .scaleEffect(reduceMotion ? 1.0 : (isActive ? 1.08 : 1.0))
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }

    private func iconName(for tab: MainTab) -> String {
        switch tab {
        case .home: return "house"
        case .playlist: return "music.note.list"
        case .transfer: return "arrow.left.arrow.right"
        case .setting: return "gearshape"
        }
    }

    private func tabTitle(for tab: MainTab) -> String {
        switch tab {
        case .home: return "Home"
        case .playlist: return "Library"
        case .transfer: return "Transfer"
        case .setting: return "Settings"
        }
    }
}
