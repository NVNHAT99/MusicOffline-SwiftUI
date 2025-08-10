//
//  SongSkeletonItemView.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/10/25.
//

import SwiftUI

struct SongSkeletonItemView: View {
    var body: some View {
        HStack(alignment: .center) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .shimmer()
        }
    }
}

#Preview {
    SongSkeletonItemView()
        .frame(height: 120)
}
