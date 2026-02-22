//
//  TransferView.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/1/25.
//

import SwiftUI

struct TransferView<ViewModel: TransferViewModelProtocol>: View {
    @StateObject private var viewModel: ViewModel
    let navigationHandler: Router<AppRoute>

    init(viewModel: ViewModel, navigationHandler: Router<AppRoute>) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.navigationHandler = navigationHandler
    }
    
    var body: some View {
        ZStack {
            Color.backgroundColor
                .ignoresSafeArea()
            VStack {
                CustomNavigationBar(type: .backButton(title: nil,
                                                      tintColor: .white,
                                                      action: {
                    viewModel.send(.handleBackAction(self.navigationHandler))
                }))
                
                
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
                            
                            Text("Then upload files from your computer.\nplease don't switch to another app or lock your phone while transfering.")
                                .lineLimit(.max)
                            
                            Image("transfer_1")
                                .resizable()
                                .aspectRatio(1.0, contentMode: .fit)
                                
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
            } // vstak
            .frame(maxWidth: .infinity)
            
            if viewModel.state.showLoading {
                Color.black.opacity(0.4).ignoresSafeArea()
                ProgressView()
                    .padding(20)
                    .background(.thinMaterial)
                    .cornerRadius(12)
            }
            
            if viewModel.state.isShowToastView {
                VStack {
                    Spacer()
                    ToastView(isShowView: viewModel.isShowToastView(),
                              message: viewModel.state.messageToastView,
                              timeShowView: .seconds(2))
                        .frame(height: 40)
                        .padding(.bottom, 16)
                }
            }
        }// zstack
    }
}

#Preview {
    let dependencies = AppDependencies.shared
    TransferView(viewModel: dependencies.makeTransferViewModel(), navigationHandler: Router<AppRoute>())
        .background(Color.backgroundColor)
}
