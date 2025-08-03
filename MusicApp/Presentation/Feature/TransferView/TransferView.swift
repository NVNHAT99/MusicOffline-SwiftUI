//
//  TransferView.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/1/25.
//

import SwiftUI

struct TransferView: View {
    // TODO: need refacter viewmodel to implement DI
    @StateObject private var viewModel: TransferViewModel = TransferViewModel()
    let navigationHandler: NavigationActionHandler
    
    var body: some View {
        ZStack {
            Color.backgroundColor
                .ignoresSafeArea()
            VStack {
                CustomNavigationBar(type: .custom(title: "Transfer audio file",
                                                  left: .init(title: "Cancel",
                                                              action: {
                    viewModel.send(.handleBacAction)
                    navigationHandler.dismissView()
                }),
                                                  right: nil))
                
                
                .foregroundStyle(.white)
                
                Spacer()
                    .frame(height: 44)
                
                VStack {
                    Button {
                        viewModel.send(.toggleServer)
                    } label: {
                        VStack {
                            Text(viewModel.state.isServerOn ? "Disconnected Server" : "Connect Server")
                        }
                        .frame(width: 160)
                        .padding(16)
                        .foregroundColor(.white)
                        .background(.red.opacity(0.8))
                        .cornerRadius(8, corners: .allCorners)
                    }
                    
                    Spacer()
                        .frame(height: 24)
                    
                    if viewModel.state.isServerOn {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Open your browser with this URL: ")
                            
                            HStack(spacing: 8) {
                                Text(viewModel.state.ipAdress ?? "")
                                    .foregroundColor(.blue)
                                
                                Button {
                                    viewModel.send(.copyIPAdress)
                                } label: {
                                    Text("Copy URL")
                                        .frame(width: 100)
                                        .padding(6)
                                        .foregroundColor(.white)
                                        .background(.black.opacity(0.8))
                                        .cornerRadius(8, corners: .allCorners)
                                }
                                
                            }
                            
                            Text("Then upload files from your computer.\nplease don't switch to another app or lock your phone while transfering, affter all file upload like this image you must tap on save button to save your file, if you don't press save button, all your file you upload will be deleted")
                                .lineLimit(.max)
                            VStack {
                                Button {
                                    viewModel.send(.completedUploadSongs)
                                } label: {
                                    VStack {
                                        Text("Save")
                                            .font(.system(size: 16, weight: .semibold))
                                            .frame(width: 94, height: 44)
                                            .foregroundColor(.white)
                                            .background(.black.opacity(0.8))
                                            .cornerRadius(8, corners: .allCorners)
                                    }
                                }
                            }.frame(maxWidth: .infinity)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 12)
                        .multilineTextAlignment(.leading)
                        .lineLimit(4)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 24)
                .background(.gray)
                .cornerRadius(10, corners: .allCorners)
                .padding()
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            
            if viewModel.state.showLoading {
                Color.black.opacity(0.4).ignoresSafeArea()
                ProgressView()
                    .padding(20)
                    .background(.thinMaterial)
                    .cornerRadius(12)
            }
        }
    }
}

#Preview {
    TransferView(navigationHandler: Router<SettingRoute>())
        .background(Color.backgroundColor)
}
