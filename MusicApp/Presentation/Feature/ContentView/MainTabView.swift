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
                
                NowPlayingView(isExpanded: $isExpland)
                    .ignoresSafeArea()
                    .embedded(navigation: .stacks, with: self.router)
                    
                
                CustomTabBar(
                    selectedTab: $tabSelection,
                    items: viewModel.tabItems,
                    type: .classic,
                    backgroundColor: .black
                )
                .frame(maxHeight: isExpland ? 0 : 70)
                .opacity(isExpland ? 0 : 1)       // fade ẩn
                .animation(.easeInOut(duration: 0.25), value: isExpland)
            }
            .zIndex(isExpland ? 2 : 1)
            
            ZStack {
                HomeView()
                    .opacity(tabSelection == .home ? 1 : 0)
                    .animation(.easeInOut(duration: 0.25), value: tabSelection)
                
                LibaryView(handler: LibaryViewViewModel())
                    .opacity(tabSelection == .playlist ? 1 : 0)
                    .animation(.easeInOut(duration: 0.25), value: tabSelection)
                
                HomeView()
                    .opacity(tabSelection == .loadSong ? 1 : 0)
                    .animation(.easeInOut(duration: 0.25), value: tabSelection)
                
                SettingView(viewModel:  SettingViewViewModel())
                    .opacity(tabSelection == .settings ? 1 : 0)
                    .animation(.easeInOut(duration: 0.25), value: tabSelection)
            }
            .padding(.bottom, 140)
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

