//
//  PlayListItemView.swift
//  MusicApp
//
//  Created by Nhat on 5/16/23.
//

import SwiftUI

struct PlayListItemView: View {
    var playListName: String = String.empty
    var onDelete: () -> Void
    var ontapItem: (() -> Void)?
    var body: some View {
        ContainerSwipeView {
            HStack {
                Image (systemName: "music.note.list")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                Text(playListName)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(size: 20, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color.backgroundColor)
            .onTapGesture {
                ontapItem?()
            }
        } onDelete: {
            onDelete()
        }
    }
}

struct PlayListItemView_Previews: PreviewProvider {
    static var previews: some View {
        PlayListItemView(playListName: String.Unkown, onDelete: {})
            .background(.gray)
            .previewLayout(.sizeThatFits)
    }
}
