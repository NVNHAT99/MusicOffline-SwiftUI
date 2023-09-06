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
    @State var arrayMP3File: [MP3File] = DocumentFileManager.shared.loadMP3File()
    @State var selectedCount: Int = 0
    @Binding var playlist: Playlist?
    var body: some View {
        VStack {
            VStack {
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
                                                                },
                                                      rightView: nil,
                                                      title: "Selection Songs")
                ) // custom navigationbar
                .frame(height: 50)
                .background(Color.backgroundColor.opacity(0.8))
                
                Spacer()
                
                List {
                    ForEach(arrayMP3File.indices, id: \.self) { index in
                        Button {
                            arrayMP3File[index].isSelected.toggle()
                            if arrayMP3File[index].isSelected {
                                selectedCount += 1
                            } else {
                                selectedCount -= 1
                            }
                        } label: {
                            SongItemView(urlMp3File: arrayMP3File[index].fileURL)
                                .foregroundColor(.white)
                                .frame(height: 32)
                        }
                        .listRowBackground(arrayMP3File[index].isSelected ? Color.red.opacity(0.5) : Color.gray )
                        .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                    }
                } // List
                .listStyle(.insetGrouped)
                
            } // VStack
            .background(Color.backgroundColor)
            
            Spacer()
            
            Button {
                let context = PersistenceController.shared.viewContext
                context.perform {
                    var songArray: [String] = playlist?.songsArray ?? []
                    for item in arrayMP3File {
                        if item.isSelected, !(songArray.contains(item.fileURL.absoluteString)) {
                            songArray.append(item.fileURL.absoluteString)
                        }
                    }
                    playlist?.songsArray = songArray
                    
                    do {
                        try context.save()
                        print("da luu bai hat thanh cong")
                    } catch {
                        print("co loi roi khong luu bai hat duoc")
                    }
                    
                    presentationMode.wrappedValue.dismiss()
                }
            } label: {
                Text("Add To Playlist")
                    .foregroundColor(.white)
            }
            .frame(width: 200, height: 48)
            .background(selectedCount > 0 ? Color.blue.opacity(0.8) : .gray)
            .cornerRadius(8, corners: .allCorners)
            .disabled(selectedCount > 0 ? false : true)
            
            Spacer()
        } // VStack
        .background(Color.backgroundColor)
        .navigationBarHidden(true)
        
    }
}

struct AddNewSongs_Previews: PreviewProvider {
    static var previews: some View {
        AddNewSongsView(playlist: .constant(nil))
    }
}
