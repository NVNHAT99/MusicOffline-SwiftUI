//
//  HomeCardSkeletonView.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/9/25.
//

import SwiftUI

struct HomeCardSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .aspectRatio(1, contentMode: .fit)
                .shimmer()
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 16)
                .padding(.top, 8)
                .shimmer()
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 80, height: 14)
                .padding(.top, 4)
                .shimmer()
        }
    }
}

#Preview {
    HomeCardSkeletonView()
}
