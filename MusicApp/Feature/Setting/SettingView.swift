//
//  SettingTabView.swift
//  MusicApp
//
//  Created by Nhat on 5/18/23.
//

import SwiftUI

struct SettingView: View {
    // MARK: - properties
    @ObservedObject var viewModel: SettingViewViewModel
    init(viewModel: SettingViewViewModel) {
        self.viewModel = viewModel
    }
    var body: some View {
        VStack {
            CustomNavigationBar(type: .larger("Setting"))
                .frame(height: 70)
                .foregroundColor(.white)
                .padding(.leading, 26)
                .background(Color.backgroundColor)
                .padding(.top, Helper.shared.safeAreaInsets?.top)
            
            GeometryReader { proxy in
                List {
                    Section {
                        VStack(alignment: .leading) {
                            Text("Transfer Mp3 files")
                                .fontWeight(.bold)
                            HStack {
                                Spacer()
                                Button {
                                    viewModel.send(intent: .toggleServer)
                                } label: {
                                    VStack {
                                        VStack {
                                            Text(viewModel.state.isServerOn ? "Disconnected Server" : "Connect Server")
                                        }
                                        .frame(width: 160)
                                        .padding(16)
                                        .foregroundColor(.white)
                                        .background(.red.opacity(0.8))
                                        .cornerRadius(8, corners: .allCorners)
                                    }
                                    
                                }
                                Spacer()
                            }
                        }
                        
                        if viewModel.state.isServerOn {
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Open your browser with this URL: ")
                                
                                HStack {
                                    Text("Http://\(viewModel.state.ipAdress ?? String.empty)/")
                                        .foregroundColor(.blue)
                                        
                                    Spacer()
                                    Button {
                                        UIPasteboard.general.string = "http://\(viewModel.state.ipAdress ?? String.empty)/"
                                        print("da copy roi day")
                                    } label: {
                                        Text("Copy URL")
                                    }
                                    .buttonStyle(.bordered)
                                }
                                
                                    
                                Text("Then upload files from your computer.\nplease don't switch to another app or lock your phone while transfering")
                            }
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                            .lineLimit(4)
                            .transition(.move(edge: .bottom))
                            .frame(width: 300)
                            
                        }
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
        .background(Color.black)
        .overlay(alignment: .bottom) {
            if viewModel.state.isShowToastView {
                ToastView(isShowView: viewModel.isShowToastView(), message: viewModel.state.messageToastView, timeShowView: .seconds(2))
                    .padding(.bottom, 16)
            }
        }
    }
}

struct SettingTabView_Previews: PreviewProvider {
    static var previews: some View {
        SettingView(viewModel: SettingViewViewModel())
    }
}
