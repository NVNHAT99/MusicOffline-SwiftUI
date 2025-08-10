//
//  HomeView.swift
//  MusicApp
//
//  Created by Nhat on 5/7/23.
//

import SwiftUI

struct MainTabView: View {
    @State private var tabSelection: MainTab
    @StateObject private var viewModel: MainTabViewVM
    
    init(tabSelection: MainTab = .home, viewModel: MainTabViewVM = MainTabViewVM()) {
        self.tabSelection = tabSelection
        _viewModel = StateObject(wrappedValue: viewModel)
        
    }
    
    var body: some View {
        ZStack {
            Color.backgroundColor
                .ignoresSafeArea()
            VStack {
                ZStack {
                    HomeView()
                        .opacity(tabSelection == .home ? 1 : 0)
                        .animation(.easeInOut(duration: 0.5), value: tabSelection)
                    
                    LibaryView(handler: LibaryViewViewModel())
                        .opacity(tabSelection == .playlist ? 1 : 0)
                        .animation(.easeInOut(duration: 0.5), value: tabSelection)
                    
                    HomeView()
                        .opacity(tabSelection == .loadSong ? 1 : 0)
                        .animation(.easeInOut(duration: 0.5), value: tabSelection)
                    
                    SettingView(viewModel:  SettingViewViewModel())
                        .opacity(tabSelection == .settings ? 1 : 0)
                        .animation(.easeInOut(duration: 0.5), value: tabSelection)
                }
                
                
                CustomTabBar(selectedTab: $tabSelection,
                             items: viewModel.tabItems,
                             type: .classic,
                             backgroundColor: Color.black)
                    .frame(height: 80)
            }
            .ignoresSafeArea(.all, edges: [.bottom])
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView(viewModel: MainTabViewVM())
    }
}

