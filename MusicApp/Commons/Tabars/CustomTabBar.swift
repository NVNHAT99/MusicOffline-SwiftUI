import SwiftUI

// MARK: - TabItem
struct TabItem<T: Hashable>: Identifiable {
    let id = UUID()
    let icon: String
    let selectedIcon: String
    let title: String
    let color: Color
    let tag: T

    init(icon: String, selectedIcon: String? = nil, title: String, color: Color = .blue, tag: T) {
        self.icon = icon
        self.selectedIcon = selectedIcon ?? icon
        self.title = title
        self.color = color
        self.tag = tag
    }
}

// MARK: - TabBarType
enum TabBarType: CaseIterable, Hashable {
    case classic, floating, minimal, curved

    var title: String {
        switch self {
        case .classic: return "Classic"
        case .floating: return "Floating"
        case .minimal: return "Minimal"
        case .curved: return "Curved"
        }
    }
}

// MARK: - TabButtonView
struct TabButtonView<T: Hashable>: View {
    let item: TabItem<T>
    let selectedTab: T
    let isCenter: Bool
    let iconSize: CGFloat
    let textVisible: Bool
    let onTap: () -> Void

    var body: some View {
        let isSelected = selectedTab == item.tag

        Button(action: onTap) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? item.selectedIcon : item.icon)
                    .font(.system(size: iconSize, weight: .medium))
                    .foregroundColor(isCenter ? .white : (isSelected ? item.color : .gray))
                    .scaleEffect(isSelected ? 1.2 : 1.0)

                if textVisible && !isCenter {
                    Text(item.title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isSelected ? item.color : .gray)
                        .opacity(isSelected ? 1 : 0.8)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Classic TabBar
struct ClassicTabBar<T: Hashable>: View {
    @Binding var selectedTab: T
    let items: [TabItem<T>]
    let backgroundColor: Color
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            ForEach(items) { item in
                TabButtonView(
                    item: item,
                    selectedTab: selectedTab,
                    isCenter: false,
                    iconSize: 22,
                    textVisible: true
                ) {
                    withAnimation(.spring()) {
                        selectedTab = item.tag
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .background(backgroundColor)
        .overlay(Divider(), alignment: .top)
    }
}

// MARK: - Floating TabBar
struct FloatingTabBar<T: Hashable>: View {
    @Binding var selectedTab: T
    let items: [TabItem<T>]

    var body: some View {
        let centerItem = items[items.count / 2]

        HStack(spacing: 0) {
            ForEach(items) { item in
                let isCenter = item.id == centerItem.id

                if isCenter {
                    Spacer().frame(width: 100, height: 1)
                } else {
                    TabButtonView(
                        item: item,
                        selectedTab: selectedTab,
                        isCenter: false,
                        iconSize: 22,
                        textVisible: true
                    ) {
                        withAnimation(.spring()) {
                            selectedTab = item.tag
                        }
                    }
                }
            }
        }
        .frame(height: 80)
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(Color.white)
                .shadow(radius: 10)
        )
        .overlay {
            TabButtonView(
                item: centerItem,
                selectedTab: selectedTab,
                isCenter: true,
                iconSize: 24,
                textVisible: false
            ) {
                withAnimation(.spring()) {
                    selectedTab = centerItem.tag
                }
            }
            .frame(width: 100, height: 100)
            .background(
                Circle()
                    .fill(LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom))
            )
            .shadow(radius: 8)
            .offset(y: -20)
        }
    }
}

// MARK: - Minimal TabBar
struct MinimalTabBar<T: Hashable>: View {
    @Binding var selectedTab: T
    let items: [TabItem<T>]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                TabButtonView(
                    item: item,
                    selectedTab: selectedTab,
                    isCenter: false,
                    iconSize: 24,
                    textVisible: false
                ) {
                    withAnimation(.spring()) {
                        selectedTab = item.tag
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(Color.black)
    }
}

// MARK: - Curved TabBar Shape
struct CurvedTabBarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = rect.midX
        var path = Path()

        path.move(to: .zero)
        path.addLine(to: CGPoint(x: center - 50, y: 0))
        path.addQuadCurve(to: CGPoint(x: center + 50, y: 0), control: CGPoint(x: center, y: -30))
        path.addLine(to: CGPoint(x: rect.maxX, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: 0, y: rect.maxY))
        path.closeSubpath()

        return path
    }
}

// MARK: - Curved TabBar
struct CurvedTabBar<T: Hashable>: View {
    @Binding var selectedTab: T
    let items: [TabItem<T>]

    var body: some View {
        ZStack(alignment: .bottom) {
            CurvedTabBarShape()
                .fill(Color.white)
                .shadow(radius: 5)

            HStack(spacing: 0) {
                ForEach(items) { item in
                    let isCenter = items.firstIndex(where: { $0.id == item.id }) == items.count / 2

                    TabButtonView(
                        item: item,
                        selectedTab: selectedTab,
                        isCenter: isCenter,
                        iconSize: isCenter ? 26 : 22,
                        textVisible: !isCenter
                    ) {
                        withAnimation(.spring()) {
                            selectedTab = item.tag
                        }
                    }
                    .offset(y: isCenter ? -30 : 0)
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 80)
    }
}

// MARK: - CustomTabBar Generic
struct CustomTabBar<T: Hashable>: View {
    @Binding var selectedTab: T
    let items: [TabItem<T>]
    let type: TabBarType
    let backgroundColor: Color
    var body: some View {
        switch type {
        case .classic:
            ClassicTabBar(selectedTab: $selectedTab, items: items, backgroundColor: backgroundColor)
        case .floating:
            FloatingTabBar(selectedTab: $selectedTab, items: items)
        case .minimal:
            MinimalTabBar(selectedTab: $selectedTab, items: items)
        case .curved:
            CurvedTabBar(selectedTab: $selectedTab, items: items)
        }
    }
}

// MARK: - Demo View
struct ContentView2: View {
    @State private var selectedTab: MainTab = .home
    @State private var tabBarType: TabBarType = .floating

    let tabItems: [TabItem<MainTab>] = [
        TabItem(icon: "house", selectedIcon: "house.fill", title: "Home", color: .blue, tag: .home),
        TabItem(icon: "books.vertical", selectedIcon: "books.vertical.fill", title: "Library", color: .green, tag: .playlist),
        TabItem(icon: "camera", selectedIcon: "camera.fill", title: "Camera", color: .orange, tag: .play),
        TabItem(icon: "heart", selectedIcon: "heart.fill", title: "Favorites", color: .red, tag: .loadSong),
        TabItem(icon: "person", selectedIcon: "person.fill", title: "Profile", color: .purple, tag: .settings)
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemGray6).ignoresSafeArea()
            VStack(spacing: 0) {
                Picker("TabBar Type", selection: $tabBarType) {
                    ForEach(TabBarType.allCases, id: \.self) { type in
                        Text(type.title).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                TabView(selection: $selectedTab) {
                    ForEach(tabItems) { item in
                        VStack {
                            Image(systemName: item.selectedIcon)
                                .font(.system(size: 80))
                                .foregroundColor(item.color)

                            Text(item.title)
                                .font(.title)
                        }
                        .tag(item.tag)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemGray6))
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                CustomTabBar(selectedTab: $selectedTab,
                             items: tabItems,
                             type: tabBarType,
                             backgroundColor: Color.backgroundColor)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

// MARK: - Preview
#Preview {
    ContentView2()
}
