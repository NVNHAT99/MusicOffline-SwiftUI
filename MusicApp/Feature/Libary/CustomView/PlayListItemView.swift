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
        VStack {
            HStack() {
                Text(playListName)
                    .frame(maxWidth: 300, alignment: .leading)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.right")
            }
            Spacer()
            Divider()
                .overlay {
                    Color.white.opacity(0.6)
                }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.trailing, 8)
    }
}

struct PlayListItemView_Previews: PreviewProvider {
    static var previews: some View {
        PlayListItemView(playListName: String.empty)
            .background(.gray)
    }
}
