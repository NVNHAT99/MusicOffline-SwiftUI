//
//  SettingTabView.swift
//  MusicApp
//
//  Created by Nhat on 5/18/23.
//

import SwiftUI

struct SettingView: View {
    // MARK: - properties
    @StateObject var viewModel: SettingViewViewModel = SettingViewViewModel()
    
    init(viewModel: SettingViewViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    var body: some View {
        VStack {
            CustomNavigationBar(type: .large(title: "Setting"))
                .frame(height: 70)
                .foregroundColor(.white)
                .padding(.leading, 26)
                .padding(.top, Helper.shared.safeAreaInsets?.top)
            
            GeometryReader { proxy in
                List {
                    Section {
                        VStack(alignment: .leading) {
                            Text("Transfer Mp3 files")
                                .fontWeight(.bold)
                        }
                        // TODO: need replace by new logic router
                        NavigationLink {
                            
                        } label: {
                            Text("Remove Ads. buy now")
                        }
                        
                    }
                    .listRowBackground(Color.headerBackground)
                    
                    
                    Section {
                        Button {
                            viewModel.send(intent: .deleteAllSongs)
                        } label: {
                            Text("Delete all songs")
                        }

                    }
                    .listRowBackground(Color.headerBackground)
                }
                .listStyle(.insetGrouped)
                .foregroundColor(.white)
                .modifier(ListBackgroundModifier())
            }
            
        }
        .ignoresSafeArea(.all)
        
        .overlay(alignment: .bottom) {
            if viewModel.state.isShowToastView {
                ToastView(isShowView: viewModel.isShowToastView(), message: viewModel.state.messageToastView, timeShowView: .seconds(2))
                    .frame(height: 40)
                    .padding(.bottom, 16)
            }
        }
    }
}

struct SettingTabView_Previews: PreviewProvider {
    static var previews: some View {
        SettingView(viewModel: SettingViewViewModel())
            .background(Color.backgroundColor)
    }
}
