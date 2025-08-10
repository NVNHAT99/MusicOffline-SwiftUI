//
//  ShimmerViewModifier.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/9/25.
//

import SwiftUI

struct ShimmerViewModifier: ViewModifier {
    @State private var moveTo: CGFloat = -1 // bắt đầu ngoài bên trái
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    let gradientWidth = geo.size.width // chiều rộng vùng sáng
                    let travel = geo.size.width + gradientWidth
                    let xOffset = moveTo * travel
                    
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.0),
                            Color.white.opacity(0.6),
                            Color.white.opacity(0.0)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: gradientWidth, height: geo.size.height)
                    .offset(x: xOffset)
                    .blendMode(.plusLighter)
                    .mask(content)
                }
                    .allowsHitTesting(false)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    moveTo = 1 // chạy từ trái sang phải
                }
            }
    }
}
