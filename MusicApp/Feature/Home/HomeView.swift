//
//  HomeTabView.swift
//  MusicApp
//
//  Created by Nhat on 5/18/23.
//

import SwiftUI

struct HomeView: View {
    // MARK: - Properties
    
    @Binding var selectedTab: Tab
    @ObservedObject private var viewModel: HomeViewHandler
    @EnvironmentObject private var playVM: PlayViewModel
    init(selectedTab: Binding<Tab>, viewModel: HomeViewHandler) {
        self._selectedTab = selectedTab
        self.viewModel = viewModel
    }
    
    var body: some View {
        GeometryReader { proxy in
            VStack  {
                Image("topImage")
                    .resizable()
                    .frame(maxHeight: proxy.size.height * 0.58)
                    .scaledToFill()
                
                Spacer()
                    .frame(height: 20)
                VStack (alignment: .leading) {
                    Text("Menu")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity ,alignment: .leading)
                        .padding(.leading, 10)
                        
                        .font(.system(size: 30))
                    VStack {
                        ScrollView {
                            ForEach(0..<viewModel.homeItems.count, id: \.self) { index in
                                if index == 0 || index == 1 {
                                    HomeItemView(data: viewModel.homeItems[index]) {
                                        switch index {
                                        case 0:
                                            selectedTab = .libary
                                        case 1:
                                            selectedTab = .setting
                                        default:
                                            selectedTab = .home
                                        }
                                    }
                                } else {
                                    NavigationLink {
                                        PlaySongView(viewModel: PlaySongHandler(playVM: playVM))
                                    } label: {
                                        HomeItemView(data: viewModel.homeItems[index], onTap: nil)
                                    }
                                }
                                
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                } // : VStack
                Spacer()
                    .frame(height: proxy.size.height * 0.12)
            }
        }
    }
}

struct HomeTabView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(selectedTab: .constant(.home), viewModel: HomeViewHandler())
    }
}
