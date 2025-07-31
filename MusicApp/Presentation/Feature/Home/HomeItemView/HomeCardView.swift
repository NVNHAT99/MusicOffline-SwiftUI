//
//  HomeCardView.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 7/17/25.
//

import SwiftUI

struct HomeCardView: View {
    var body: some View {
        VStack {
            Image("demoThumbnail2")
                .resizable()
                .scaledToFit()
                .aspectRatio(1, contentMode: .fit)
            
            Text("Monster Go Bump")
                .foregroundStyle(.white)
            Text("Uknow")
                .foregroundStyle(.white)
                .font(.subheadline)
        }
    }
}

#Preview {
    HomeCardView()
        .frame(width: 200)
        .background(Color.backgroundColor)
}
