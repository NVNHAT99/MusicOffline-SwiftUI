//
//  TransferView.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/1/25.
//

import SwiftUI

struct TransferView: View {
    
    @StateObject private var viewModel: TransferViewModel = TransferViewModel()
    
    var body: some View {
        VStack {
            CustomNavigationBar(type: .custom(title: "Transfer audio file",
                                              left: .init(title: "Cancel", action: {
                
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
                                UIPasteboard.general.string = "day la fake url"
                                print("da copy roi day")
                            } label: {
                                Text("Copy URL")
                                    .frame(width: 100)
                                    .padding(6)
                                    .foregroundColor(.white)
                                    .background(.black.opacity(0.8))
                                    .cornerRadius(8, corners: .allCorners)
                            }
                            
                        }
                        
                        Text("Then upload files from your computer.\nplease don't switch to another app or lock your phone while transfering, affter all file upload like this image you must tap on save button to save your file, if you don't press save button, you must restart your app to save those files again")
                            .lineLimit(.max)
                        VStack {
                            Button {
                                
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
    }
}

#Preview {
    TransferView()
        .background(Color.backgroundColor)
}
