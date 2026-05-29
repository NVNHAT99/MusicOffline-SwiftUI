//
//  SongSkeletonItemView.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/10/25.
//

import SwiftUI

struct SongSkeletonItemView: View {
    private let base = Color.white.opacity(0.08)

    var body: some View {
        HStack(alignment: .center) {
            RoundedRectangle(cornerRadius: 8)
                .fill(base)
                .shimmer()
        }
    }
}

#Preview {
    SongSkeletonItemView()
        .frame(height: 120)
        .background(Color.backgroundColor)
}
