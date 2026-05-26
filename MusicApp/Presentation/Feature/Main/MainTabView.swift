//
//  MainTabView.swift
//  MusicApp
//
//  Created by Claude
//  Following EasyFax AppTabBar pattern
//

import SwiftUI

struct MainTabView: View {
    @State var currentTab: MainTab = .home
    @State private var bottomSafeArea: CGFloat = 0
    @StateObject private var router = Router<AppRoute>()
    @EnvironmentObject var container: DIContainer

    init() {
        // Hide default tab bar - using custom one
        UITabBar.appearance().isHidden = true
    }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentTab) {
                // Home Tab
                HomeView(
                    viewModel: container.makeHomeViewModel(),
                    onPlaylistTap: { playlist in
                        router.route(to: .playlistDetail(id: playlist.id))
                    }
                )
                .tag(MainTab.home)

                // Library Tab
                LibaryView(handler: container.makeLibaryViewViewModel())
                .tag(MainTab.playlist)

                // Transfer Tab
                TransferView(
                    viewModel: container.makeTransferViewModel(),
                    navigationHandler: router
                )
                .tag(MainTab.transfer)

                // Setting Tab
                SettingView(viewModel: container.makeSettingViewModel())
                .tag(MainTab.setting)
            }
            .animation(.easeInOut, value: currentTab) // Smooth tab transition

            customTabBar
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .environmentObject(router)
        .onAppear {
            router.factory = container
            updateSafeArea()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            updateSafeArea()
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchMainTab)) { notif in
            guard let tab = notif.object as? MainTab else { return }
            router.popToRoot()
            currentTab = tab
        }
    }

    private func updateSafeArea() {
        guard let window = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive })
            as? UIWindowScene else {
            return
        }

        let newSafeArea = window.windows.first?.safeAreaInsets.bottom ?? 0
        if newSafeArea != bottomSafeArea {
            bottomSafeArea = newSafeArea
        }
    }

    private var customTabBar: some View {
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
        Button {
            currentTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: iconName(for: tab))
                    .font(.system(size: 24))
                    .foregroundColor(currentTab == tab ? .white : .gray)

                Text(tabTitle(for: tab))
                    .font(.system(size: 10))
                    .foregroundColor(currentTab == tab ? .white : .gray)
            }
            .frame(maxWidth: .infinity)
        }
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

// MARK: - Preview
#Preview {
    let container = DIContainer(
        appState: AppState.shared,
        useCases: DIContainer.UseCases.create(
            songRepository: SongRepository(coreData: CoreDataManager.shared),
            playlistRepository: PlaylistRepository(coreDataService: CoreDataManager.shared),
            songMetadataRepository: SongMetadataRepository(),
            webServerService: WebServerGCDService.shared,
            coreDataManager: CoreDataManager.shared
        ),
        services: DIContainer.Services.createDefault()
    )

    return MainTabView()
        .environmentObject(container)
        .environmentObject(Router<AppRoute>())
}
