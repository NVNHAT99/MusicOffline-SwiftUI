//
//  PlayListItemView.swift
//  MusicApp
//
//  Created by Nhat on 5/16/23.
//

import SwiftUI

struct PlaylistItem {
    let imageName: String
    let playlistName: String
    let subTitle: String
}

struct PlayListItemView: View {
    var data: PlaylistItem
    var sizeImage: CGSize
    var body: some View {
        VStack(alignment: .leading) {
            Image(data.imageName)
                .resizable()
                .frame(width: sizeImage.width, height: sizeImage.height)
                .scaledToFill()
                .clipShape(RoundedRectangle(cornerRadius: 17))
            VStack(alignment: .leading ,spacing: 10) {
                Text(data.playlistName)
                    .fontWeight(.bold)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                Text(data.subTitle)
                    .fontWeight(.bold)
                    .font(.system(size: 14))
                    .foregroundColor(Color.whiteAlpha30)
            }
            
        }
        
    }
}

struct PlayListItemView_Previews: PreviewProvider {
    static var previews: some View {
        PlayListItemView(data: PlaylistItem(imageName: "templePlaylist", playlistName: "hallo", subTitle: "30 songs"), sizeImage: CGSize(width: 150, height: 150))
            .background(.gray)
    }
}
