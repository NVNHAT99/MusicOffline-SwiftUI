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
    var urlMp3File: String?
    // MARK: - PROPERTIES WRAPER
    @State private var song: SongInfo?
    
    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 3)
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
                Spacer()
                    .frame(height: 3)
            }
            
        }
        .task {
            do {
                song = try await DocumentFileManager.shared.loadMetadata(stringURL: urlMp3File ?? String.empty)
            } catch {
                print("da load data bi loi \(error)")
            }
        }
    }
}

struct SongView_Previews: PreviewProvider {
    static var previews: some View {
        SongItemView(urlMp3File: nil)
            .previewLayout(.sizeThatFits)
            .frame(height: 40)
            .background(.blue)
    }
}
