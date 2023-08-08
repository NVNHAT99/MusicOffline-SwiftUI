//
//  SongItemView.swift
//  MusicApp
//
//  Created by Nhat on 7/13/23.
//

import SwiftUI

struct SongItemData {
    let name: String
    let image: String
    let time: String
    let albumName: String
}

struct SongItemView: View {
    // MARK: - PROPERTIES
    var data: SongItemData
    
    var body: some View {
        VStack(spacing: 5){
            HStack {
                VStack(alignment: .leading) {
                    Text(data.name)
                        .lineLimit(1)
                    HStack {
                        Text(data.albumName)
                        Spacer()
                        Text(data.time)
                    }
                }
                Spacer()
                    .frame(width: 5)
            }
            
        }
        .padding([.leading, .trailing], 15)
        .padding(.top, 5)
    }
}

struct SongView_Previews: PreviewProvider {
    static var previews: some View {
        SongItemView(data: SongItemData(name: "nothing",
                                        image: "circle",
                                        time: "3:02",
                                        albumName: "nothing 2"))
            .previewLayout(.sizeThatFits)
    }
}
