//
//  SplashView.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 9/15/25.
//

import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var scaleEffect = 0.8
    @State private var opacity = 0.5
    @ObservedObject var mainTabViewModel: MainTabViewVM
    
    var body: some View {
        if isActive {
            MainTabView(viewModel: mainTabViewModel)
        } else {
            ZStack {
                // MARK: - Full screen bg color
                Color.backgroundColor
                
                // MARK: - Omron logo
                VStack {
                    Image("app_icon")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } //: VStack
            } //: ZStack
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                // Delay trước khi chuyển sang màn chính
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
        }
    }
}
