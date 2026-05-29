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
    @State private var isNowPlayingExpanded: Bool = false
    @StateObject private var router = Router<AppRoute>()
    @StateObject private var nowPlayingViewModel = NowPlayingViewModel()
    @EnvironmentObject var container: DIContainer

    init() {
        // Hide default tab bar - using custom one
        UITabBar.appearance().isHidden = true
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main tab content + custom tab bar
            VStack(spacing: 0) {
                TabView(selection: $currentTab) {
                    homeTab
                        .tag(MainTab.home)

                    LibaryView(handler: container.makeLibaryViewViewModel())
                        .tag(MainTab.playlist)

                    TransferView(
                        viewModel: container.makeTransferViewModel(),
                        navigationHandler: router
                    )
                    .tag(MainTab.transfer)

                    SettingView(viewModel: container.makeSettingViewModel())
                        .tag(MainTab.setting)
                }
                .animation(.easeInOut, value: currentTab)

                customTabBar
            }

            // Mini + full player coordinator. Visible only when a song is loaded.
            // NowPlayingView already handles artwork loading + mini↔full swap.
            if nowPlayingViewModel.state.currentSong != nil {
                NowPlayingView(
                    isExpanded: $isNowPlayingExpanded,
                    viewModel: nowPlayingViewModel
                )
                .environmentObject(router)
                .padding(.bottom, isNowPlayingExpanded ? 0 : max(96, 96 + bottomSafeArea - 10))
                .padding(.horizontal, isNowPlayingExpanded ? 0 : 8)
                .ignoresSafeArea(.all, edges: isNowPlayingExpanded ? .all : [])
                .zIndex(50)
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .environmentObject(router)
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: isNowPlayingExpanded)
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
            // Switching tabs while the full player is open is jarring — collapse.
            if isNowPlayingExpanded { isNowPlayingExpanded = false }
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

    // HomeView wraps this VM in its own @StateObject, so it retains the first
    // instance for the view's lifetime; extracting the tab keeps body tidy.
    private var homeTab: some View {
        HomeView(
            viewModel: container.makeHomeViewModel(),
            onPlaylistTap: { playlist in
                router.route(to: .playlistDetail(id: playlist.id))
            }
        )
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
