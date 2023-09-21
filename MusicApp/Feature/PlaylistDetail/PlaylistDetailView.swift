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
    @ObservedObject var handler: PlaylistDetailsHandler
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
                        AddNewSongsView(playlist: handler.playlistBinding())
                    }, label: {
                        Text("Add news")
                    })
                )
            }, title: handler.state.playlist?.name ?? String.empty)) // Custom NavigationBar
            .frame(height: 50)
            .background(Color.backgroundColor)
            
            LazyVStack(spacing: 0) {
                ForEach(handler.songsForUI) {
                    item in
                    SwiperToDeleteView(content: {
                        SongItemView(urlMp3File: item.songUrlStr)
                            .foregroundColor(.white)
                            .onTapGesture {
                                handler.send(intent: .playSong(index: item.index))
                            }
                            .background(Color.backgroundColor)
                    }, deleteAction: {
                        handler.send(intent: .deleteSong(index: item.index))
                    })
                    .frame(height: 40)
                }
            }
            .background(Color.backgroundColor)
            .padding(.horizontal, 16)
            Spacer()
        }
        .navigationBarHidden(true)
        .background(Color.backgroundColor)
    }
}

struct LibaryDetail_Previews: PreviewProvider {
    static var previews: some View {
        PlaylistDetailView(handler: PlaylistDetailsHandler())
    }
}

