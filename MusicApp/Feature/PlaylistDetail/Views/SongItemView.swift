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
                HStack(alignment: .center) {
                    VStack {
                        Spacer()
                        if let image = song?.thumbnail {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: proxy.size.height - 16)
                        } else {
                            Image("musicRecord")
                                .resizable()
                                .scaledToFit()
                                .frame(height: proxy.size.height - 16)
                        }
                        Spacer()
                    }
                    
                    Spacer()
                        .frame(width: 16)
                    VStack(alignment: .leading) {
                        Text(song?.name ?? String.empty)
                            .lineLimit(1)
                            .frame(alignment: .leading)
                        Text(song?.albumName ?? "Unkonw")
                            .frame(alignment: .leading)
                    }
                }
                .frame(height: proxy.size.height - 4)
                Spacer()
            }
            .frame(height: proxy.size.height)
            .padding(.horizontal, 8)
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
