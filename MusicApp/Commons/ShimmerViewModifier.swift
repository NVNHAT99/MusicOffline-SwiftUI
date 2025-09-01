//
//  ShimmerViewModifier.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/9/25.
//

import SwiftUI

struct ShimmerViewModifier: ViewModifier {
    @State private var moveTo: CGFloat = -1
    @State private var size: CGSize = .zero
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            size = geo.size
                        }
                }
            )
            .overlay(
                shimmerLayer()
                    .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    moveTo = 1
                }
            }
    }
    
    @ViewBuilder
    private func shimmerLayer() -> some View {
        // Dải sáng to hơn width để đảm bảo phủ trọn khi chạy
        let gradientWidth = size.width * 1.5
        let travel = size.width + gradientWidth
        let xOffset = moveTo * travel
        
        LinearGradient(
            gradient: Gradient(colors: [
                Color.white.opacity(0.0),
                Color.white.opacity(0.5),
                Color.white.opacity(0.0)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(width: gradientWidth, height: size.height)
        .offset(x: xOffset)
        .blendMode(.plusLighter)
    }
}
