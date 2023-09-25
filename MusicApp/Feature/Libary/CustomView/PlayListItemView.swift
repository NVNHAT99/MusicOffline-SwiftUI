//
//  PlayListItemView.swift
//  MusicApp
//
//  Created by Nhat on 5/16/23.
//

import SwiftUI

struct PlayListItemView: View {
    var playListName: String = String.empty
    var body: some View {
        GeometryReader { proxy in
            VStack {
                Spacer()
                HStack() {
                    Text(playListName)
                        .frame(maxWidth: 200, alignment: .leading)
                        .font(.system(size: 16, weight: .semibold))
                        .lineLimit(1)
                }
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.trailing, 8)
            .frame(height: proxy.size.height)
        }
    }
}

struct PlayListItemView_Previews: PreviewProvider {
    static var previews: some View {
        PlayListItemView(playListName: String.Unkown)
            .background(.gray)
            .previewLayout(.sizeThatFits)
    }
}
