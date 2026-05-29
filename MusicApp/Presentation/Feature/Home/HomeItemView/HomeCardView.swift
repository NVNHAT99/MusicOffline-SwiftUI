//
//  HomeCardView.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 7/17/25.
//

import SwiftUI

struct HomeCardView: View {
    let title: String
    let imageName: String
    let subTitle: String
    var body: some View {
        VStack {
            Image("demoThumbnail2")
                .resizable()
                .scaledToFit()
                .aspectRatio(1, contentMode: .fit)
            
            Text(title)
                .font(AppFont.callout().weight(.medium))
                .foregroundStyle(Color.primaryText)
                .lineLimit(1)
            if !subTitle.isEmpty {
                Text(subTitle)
                    .foregroundStyle(Color.secondaryText)
                    .font(AppFont.caption())
            } else {
                Spacer()
            }
        }
    }
}

#Preview {
    HomeCardView(title: "demoThumbnail2",
                 imageName: "Monster Go Bump",
                 subTitle: "Uknow")
        .frame(width: 200)
        .background(Color.backgroundColor)
}
