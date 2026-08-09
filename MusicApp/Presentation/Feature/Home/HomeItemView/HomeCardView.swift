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
        VStack(alignment: .leading, spacing: 8) {
            Image("demoThumbnail2")
                .resizable()
                .scaledToFill()
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: DesignToken.Radius.md, style: .continuous))
                .shadow(color: Color.accentPrimary.opacity(0.25), radius: 10, x: 0, y: 6)

            Text(title)
                .font(AppFont.callout().weight(.semibold))
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
