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
            Spacer()
            HStack() {
                Text(playListName)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(size: 20, weight: .semibold))
                    .lineLimit(1)
            }
            Spacer()
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(Color.color292C2E)
        .cornerRadius(8, corners: .allCorners)
    }
}

struct PlayListItemView_Previews: PreviewProvider {
    static var previews: some View {
        PlayListItemView(playListName: String.Unkown)
            .background(.gray)
            .previewLayout(.sizeThatFits)
    }
}
