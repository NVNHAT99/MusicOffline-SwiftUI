//
//  HomeItemDetailView.swift
//  MusicApp
//
//  Created by Nhat on 5/24/23.
//

import SwiftUI

struct HomeItemDetailView: View {
    var data: HomeItemViewData
    var body: some View {
        VStack(alignment: .leading) {
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.gray)
            HStack(spacing: 20) {
                Image(systemName: data.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                Text(data.title)
                    .fontWeight(.bold)
                    .font(.system(size: 16))
            }
            if !data.isHiddenBottom {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray)
            }
        }
        .padding([.leading, .trailing], 20)
    }
}

struct HomeItemDetailView_Previews: PreviewProvider {
    static var previews: some View {
        HomeItemDetailView(data: HomeItemViewData(imageName: "book.fill", title: "Libary", isHiddenBottom: true))
    }
}
