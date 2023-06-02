//
//  HomeItemView.swift
//  MusicApp
//
//  Created by Nhat on 5/11/23.
//

import SwiftUI

struct HomeItemViewData: Identifiable {
    let id = UUID()
    let imageName: String
    let title: String
    let isHiddenBottom: Bool
}

struct HomeItemView: View {
    var data: HomeItemViewData
    let onTap: (() -> Void)?
    @State private var isPresented = false
    var body: some View {
        if let onTap = onTap {
            HomeItemDetailView(data: data)
                .onTapGesture {
                    onTap()
                }
        } else {
            HomeItemDetailView(data: data)
        }
    }
}

struct HomeItemView_Previews: PreviewProvider {
    static var previews: some View {
        HomeItemView(data: HomeItemViewData(imageName: "book.fill", title: "Libary", isHiddenBottom: true), onTap: {})
            .previewLayout(.sizeThatFits)
    }
}
