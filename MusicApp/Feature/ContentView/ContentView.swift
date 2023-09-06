//
//  HomeView.swift
//  MusicApp
//
//  Created by Nhat on 5/7/23.
//

import SwiftUI

struct ContentView: View {
    @State private var tabSelection: Tab
    @ObservedObject private var viewModel: ContentViewHandler
    @StateObject var libaryViewHandler: LibaryViewHandler = LibaryViewHandler()
    @StateObject var playVM = PlayViewModel()
    init(tabSelection: Tab = .home, viewModel: ContentViewHandler) {
        self.tabSelection = tabSelection
        self.viewModel = viewModel
    }
    
    var body: some View {
        GeometryReader { proxy in
            NavigationStack {
                TabView(selection: $tabSelection) {
                    //top image
                    HomeView(selectedTab: $tabSelection, viewModel: HomeViewHandler())
                    .ignoresSafeArea(.all)
                    .background(Color.backgroundColor)
                    .foregroundColor(.white)
                    .tag(Tab.home)
                   
                    
                    //second tabview
                    LibaryView(handler: libaryViewHandler)
                        .tag(Tab.libary)
                                            
                    // Third tabview
                    SettingView()
                        .tag(Tab.setting)

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
                .animation(.default, value: tabSelection)
            }
            .ignoresSafeArea(.all)
            .navigationBarHidden(true)
        }
        .environmentObject(playVM)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: ContentViewHandler())
    }
}

