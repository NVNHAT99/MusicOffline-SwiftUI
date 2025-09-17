//
//  HomeView.swift
//  MusicApp
//
//  Created by Nhat on 5/7/23.
//

import SwiftUI

struct MainTabView: View {
    @State private var isExpland: Bool = false
    @State private var tabSelection: MainTab
    @StateObject private var viewModel: MainTabViewVM
    @StateObject private var reloadManager: TabReloadManager
    @StateObject var router = Router<MainTabRoute>()
    
    init(tabSelection: MainTab = .home,
         viewModel: MainTabViewVM = MainTabViewVM(),
         reloadManager: TabReloadManager = TabReloadManager()) {
        self.tabSelection = tabSelection
        _viewModel = StateObject(wrappedValue: viewModel)
        _reloadManager = StateObject(wrappedValue: reloadManager)
    }
    
    var body: some View {
        ZStack {
            Color.backgroundColor
                .ignoresSafeArea()
                .zIndex(0)
            
            VStack(spacing: 0) {
                
                if viewModel.isShowNowPlaying {
                    NowPlayingView(isExpanded: $isExpland)
                        .ignoresSafeArea()
                        .embedded(navigation: .stacks, with: self.router)
                } else {
                    Spacer()
                }
                    
                CustomTabBar(
                    selectedTab: $tabSelection,
                    items: viewModel.tabItems,
                    type: .classic,
                    backgroundColor: .black
                )
                .frame(maxHeight: isExpland ? 0 : 80)
                .opacity(isExpland ? 0 : 1)       // fade ẩn
                .animation(.easeInOut(duration: 0.25), value: isExpland)
            }
            .zIndex(isExpland ? 2 : 1)
            
            TabView(selection: $tabSelection) {
                HomeView(viewModel: .init(), onPlaylistTap: { playlist in
                    tabSelection = .playlist
                    // Sau 1.5s gửi noti
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        NotificationCenter.default.post(name: .openPlaylistDetail, object: playlist)
                    }
                })
                .animation(.easeInOut(duration: 0.25), value: tabSelection)
                .tag(MainTab.home)
                .toolbar(.hidden, for: .tabBar)
                
                LibaryView(handler: LibaryViewViewModel())
                    .animation(.easeInOut(duration: 0.25), value: tabSelection)
                    .tag(MainTab.playlist)
                    .toolbar(.hidden, for: .tabBar)
                
                SettingView(viewModel:  SettingViewViewModel())
                    .animation(.easeInOut(duration: 0.25), value: tabSelection)
                    .tag(MainTab.settings)
                    .toolbar(.hidden, for: .tabBar)
            }
            .background(Color.clear)
            .padding(.bottom, viewModel.isShowNowPlaying ? 160 : 80)
            .zIndex(isExpland ? 1 : 2)
            
        }
        .environmentObject(self.router)
        .ignoresSafeArea(.all, edges: [.bottom])
        .onChange(of: self.tabSelection, { oldValue, newValue in
            if oldValue != newValue {
                reloadManager.resetTab = [newValue]
            }
        })
        .onAppear(perform: {
            self.reloadManager.resetTab = [.home]
        })
        .environmentObject(reloadManager)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView(viewModel: MainTabViewVM())
    }
}

