//
//  SongItemView.swift
//  MusicApp
//
//  Created by Nhat on 7/13/23.
//
import Foundation
import SwiftUI

struct SongInfo {
    let name: String
    let albumName: String
    let image: String
    let singerName: String
    let thumbnail: UIImage?
    let duration: Double
}

struct SongItemView: View {
    // MARK: - PROPERTIES
    var urlMp3File: URL?
    // MARK: - PROPERTIES WRAPER
    @State private var song: SongInfo?
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if let image = song?.thumbnail {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                } else {
                    Image("musicRecord")
                        .resizable()
                        .scaledToFit()
                }
                Spacer()
                    .frame(width: 16)
                VStack(alignment: .leading) {
                    Text(song?.name ?? String.empty)
                        .lineLimit(1)
                    HStack {
                        Text(song?.albumName ?? "Unkonw")
                        Spacer()
                    }
                }
            }
        }
        .padding([.leading, .trailing], 0)
        .task {
            if let url = urlMp3File {
                do {
                    song = try await DocumentFileManager.shared.loadMetadata(url: url)
                    let newName: String = song?.name == String.empty ? url.lastPathComponent.replacingOccurrences(of: ".mp3", with: "") : (song?.name ?? String.empty)
                    let newAlbumName: String = song?.albumName == String.empty ? "Unkown" : (song?.albumName ?? String.empty)
                    song = .init(name: newName,
                                 albumName: newAlbumName,
                                 image: song?.image ?? String.empty,
                                 singerName: song?.singerName ?? String.empty,
                                 thumbnail: song?.thumbnail,
                                 duration: song?.duration ?? 0)
                } catch {
                    print("da load data bi loi \(error)")
                }
            }
        }
    }
}

struct SongView_Previews: PreviewProvider {
    static var previews: some View {
        SongItemView(urlMp3File: nil)
            .previewLayout(.sizeThatFits)
            .background(.blue)
    }
}
