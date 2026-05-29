//
//  ToastView.swift
//  MusicApp
//
//  Created by Nhat on 10/1/23.
//

import SwiftUI

struct ToastView: View {
    @Binding var isShowView: Bool
    let message: String
    let timeShowView: DispatchTimeInterval

    var body: some View {
        Text(message)
            .font(AppFont.callout())
            .foregroundColor(.primaryText)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .lineLimit(2)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.15))
                    .background(Capsule().fill(Color.backgroundColor))
            )
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.3), radius: 6, y: 2)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(MotionToken.springStandard, value: isShowView)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + timeShowView) {
                    withAnimation(MotionToken.springStandard) {
                        isShowView = false
                    }
                }
            }
    }
}

struct ToastView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack(alignment: .bottom) {
            Color.backgroundColor.ignoresSafeArea()
            ToastView(isShowView: .constant(true),
                      message: "Playlist saved",
                      timeShowView: .seconds(2))
                .padding(.bottom, 24)
        }
    }
}
