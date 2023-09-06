//
//  PlaylistDetail.swift
//  MusicApp
//
//  Created by Nhat on 7/13/23.
//

import SwiftUI
import CoreData

struct PlaylistDetailView: View {
    // MARK: - PROPERTIES
    
    // MARK: - PROPERTIES WRAPER
    @State var isPresented: Bool = false
    @Environment(\.presentationMode) private var presentationMode
    @State var playlist: Playlist?
    @EnvironmentObject private var playVM: PlayViewModel
    var body: some View {
        VStack(alignment: .leading) {
            CustomNavigationBar(type: .twoButtons(leftView: {
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

            }, rightView: {
                AnyView(
                    NavigationLink(destination: {
                        AddNewSongsView(playlist: $playlist)
                    }, label: {
                        Text("Add news")
                    })
                )
            }, title: playlist?.name ?? String.empty)) // Custom NavigationBar

            .frame(height: 50)
            .background(Color.backgroundColor)
            List {
                if let playlist = playlist {
                    ForEach(Array(playlist.songsArray.enumerated()), id: \.offset) { index, item in
                        if let url = URL(string: item) {
                            Button {
                                PlaylistManager.shared.updatePlaylist(playlist: playlist, currentIndex: index)
                                PlaylistManager.shared.playSong(urlString: item)
                            } label: {
                                SongItemView(urlMp3File: url)
                                    .frame(height: 32)
                                    .foregroundColor(.white)
                            }
                            .listRowBackground(Color.gray)

                        }
                    }
                }
            }
            .modifier(ListBackgroundModifier())

        }
        .navigationBarHidden(true)
        .background(Color.backgroundColor)
    }
}

struct LibaryDetail_Previews: PreviewProvider {
    static var previews: some View {
        PlaylistDetailView()
    }
}

