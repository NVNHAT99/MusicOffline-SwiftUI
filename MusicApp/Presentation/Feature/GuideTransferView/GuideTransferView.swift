//
//  GuideTransferView.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/1/25.
//

import SwiftUI

struct GuideTransferView: View {
    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    Text("Step 1:")
                        .font(AppFont.headline())
                        .foregroundColor(.primaryText)
                    Image("demoThumbnail2")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                    Text("Step 1:")
                        .font(AppFont.headline())
                        .foregroundColor(.primaryText)
                    Image("demoThumbnail2")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                    Text("Step 1:")
                        .font(AppFont.headline())
                        .foregroundColor(.primaryText)
                    Image("demoThumbnail2")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    GuideTransferView()
}
