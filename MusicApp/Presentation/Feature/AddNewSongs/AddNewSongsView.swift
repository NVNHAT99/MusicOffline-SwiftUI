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
    
    let onCompleted: (Result<Bool, Error>) -> Void
    var body: some View {
        VStack {
            CustomNavigationBar(type: .custom(title: "Selection Songs",
                                              left: .init(action: {
                
                                                                    }),
                                              right: nil)) // custom navigationbar
            .frame(height: 50)
            .background(Color.black)
            
            if viewModel.state.arrayMP3File.count <= 0 {
                VStack(alignment: .center) {
                    Spacer()
                    Text("You don't have any song to add")
                        .foregroundColor(.white)
                        .frame(alignment: .center)
                        .transition(.opacity)
                    Spacer()
                }
                .frame(width: Helper.shared.keyWindown?.bounds.width ?? 200)
            } else {
                List {
                    ForEach(viewModel.state.arrayMP3File.indices, id: \.self) { index in
                        Button {
                            viewModel.send(intent: .toggleSelectedAt(index: index))

                        } label: {
                            SongItemView()
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                        }
                        .listRowBackground(Color.backgroundColor)
                        .listRowInsets(EdgeInsets())
                    }
                }
                .modifier(ListBackgroundModifier())
                .cornerRadius(8, corners: .allCorners)
            }
            
            Spacer()
            
            Button {
                viewModel.send(intent: .addToPlaylist(onCompleted: { result in
                    onCompleted(result)
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
            Spacer()
                .frame(height: 16)
        } // VStack
        .background(Color.black)
        .navigationBarHidden(true)
        .onAppear {
            viewModel.send(intent: .loadListSong)
        }
    }
}

struct AddNewSongs_Previews: PreviewProvider {
    static var previews: some View {
        AddNewSongsView(viewModel: AddNewSongsViewModel(), onCompleted: {_ in})
    }
}
