//
//  AddNewSongs.swift
//  MusicApp
//
//  Created by Nhat on 8/5/23.
//

import SwiftUI

struct AddNewSongsView: View {
    // MARK: - PROPERTIES
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var viewModel: AddNewSongsViewModel
    
    var body: some View {
        VStack {
            CustomNavigationBar(type: .twoButtons(
                leftView: {
                    AnyView(
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            HStack(spacing: 2) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                        }
                    )
                },
                rightView: nil,
                title: "Selection Songs")
            ) // custom navigationbar
            .frame(height: 50)
            .background(Color.black)
            if viewModel.state.arrayMP3File.count <= 0 {
                VStack(alignment: .center) {
                    Spacer()
                    Text("Don't have any songs to add to playlist!")
                        .foregroundColor(.white)
                        .frame(alignment: .center)
                    Spacer()
                }
            } else {
                List {
                    ForEach(viewModel.state.arrayMP3File.indices, id: \.self) { index in
                        Button {
                            viewModel.send(intent: .toggleSelectedAt(index: index))
                            
                        } label: {
                            SongItemView(urlMp3File: viewModel.state.arrayMP3File[index].fileURL.absoluteString)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                        }
                        .listRowBackground(viewModel.state.arrayMP3File[index].isSelected ? Color.red.opacity(0.5) : Color.backgroundColor)
                        .listRowInsets(EdgeInsets())
                    }
                }
                .modifier(ListBackgroundModifier())
                .cornerRadius(8, corners: .allCorners)
            }
            
            Spacer()
            
            Button {
                viewModel.send(intent: .addToPlaylist(onCompleted: {
                    presentationMode.wrappedValue.dismiss()
                }))
            } label: {
                Text("Add To Playlist")
            }
            .frame(width: 200, height: 48)
            .background(viewModel.state.selectedCount > 0 ? Color.blue.opacity(0.8) : .gray)
            .cornerRadius(8, corners: .allCorners)
            .disabled(viewModel.state.selectedCount > 0 ? false : true)
            .foregroundColor(.white)
            
            Spacer()
                .frame(height: 16)
        } // VStack
        .background(Color.black)
        .navigationBarHidden(true)
    }
}

struct AddNewSongs_Previews: PreviewProvider {
    static var previews: some View {
        AddNewSongsView(viewModel: AddNewSongsViewModel(playlist: nil))
    }
}
