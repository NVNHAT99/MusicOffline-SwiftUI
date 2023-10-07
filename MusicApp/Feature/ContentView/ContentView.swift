//
//  HomeView.swift
//  MusicApp
//
//  Created by Nhat on 5/7/23.
//

import SwiftUI

struct ContentView: View {
    @State private var tabSelection: Tab
    @ObservedObject private var viewModel: ContentViewViewModel
    @StateObject var libaryViewHandler: LibaryViewViewModel = LibaryViewViewModel()
    @StateObject var playVM = PlayViewModel()
    @StateObject var settingViewVM = SettingViewViewModel()
    init(tabSelection: Tab = .home, viewModel: ContentViewViewModel) {
        self.tabSelection = tabSelection
        self.viewModel = viewModel
    }
    
    var body: some View {
        GeometryReader { proxy in
            NavigationStack {
                TabView(selection: $tabSelection) {
                    //top image
                    HomeView(selectedTab: $tabSelection, viewModel: HomeViewViewModel())
                    .ignoresSafeArea(.all)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .tag(Tab.home)
                    .transition(.slide)
                   
                    
                    //second tabview
                    LibaryView(handler: libaryViewHandler)
                        .tag(Tab.libary)
                        .transition(.slide)
                                            
                    // Third tabview
                    SettingView(viewModel: settingViewVM)
                        .tag(Tab.setting)
                        .transition(.slide)

                }
                .overlay(alignment: .bottom) {
                    VStack {
                        Spacer()
                        CustomTabar(tabSelection: $tabSelection, items: viewModel.tabItems)
                            .frame(height: proxy.size.height * 0.11)
                            .cornerRadius(24, corners: [.topLeft, .topRight])
                            .background(Color.backgroundColor)
                    }
                    .ignoresSafeArea(.all)
                }
                
            }
            .ignoresSafeArea(.all)
            .navigationBarHidden(true)
        }
        .environmentObject(playVM)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: ContentViewViewModel())
    }
}

