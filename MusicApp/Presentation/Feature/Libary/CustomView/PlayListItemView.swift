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
            HStack(spacing: DesignToken.Spacing.md) {
                Image(systemName: "music.note.list")
                    .resizable()
                    .scaledToFit()
                    .frame(width: DesignToken.IconSize.md, height: DesignToken.IconSize.md)
                    .foregroundStyle(Color.accentPrimary)
                Text(playListName)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(AppFont.headline())
                    .lineLimit(1)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.mutedText)
            }
            .foregroundColor(.primaryText)
            .padding(.horizontal, DesignToken.Spacing.md)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color.backgroundColor)
            .contentShape(Rectangle())
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
