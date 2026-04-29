//
//  SettingTabView.swift
//  MusicApp
//
//  Created by Nhat on 5/18/23.
//

import SwiftUI

struct SettingView<ViewModel: SettingViewViewModelProtocol>: View {
    // MARK: - properties
    @StateObject var viewModel: ViewModel
    @StateObject private var router = Router<AppRoute>()
    @EnvironmentObject private var container: DIContainer

    init(viewModel: ViewModel) {
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
                        Button {
                            self.router.route(to: .transferAudio)
                        } label: {
                            Text("Transfer Mp3 files")
                                .fontWeight(.bold)
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
        .background(Color.backgroundColor)
        .withRouting(router: self.router)
        .onAppear { router.factory = container }
    }
}

struct SettingTabView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview using DIContainer (if available) or manual initialization
        let viewModel = SettingViewViewModel()
        return SettingView(viewModel: viewModel)
            .background(Color.backgroundColor)
    }
}
