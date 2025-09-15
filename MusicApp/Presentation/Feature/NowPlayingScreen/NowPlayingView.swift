//
//  NowPlayingView.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/28/25.
//

import SwiftUI
import UIKit

struct NowPlayingView: View {
    @Binding var isExpanded: Bool
    @StateObject var viewModel = NowPlayingViewModel()
    @EnvironmentObject var router: Router<MainTabRoute>
    // Constants for layout
    private let miniPlayerHeight: CGFloat = 80
    private let cornerRadius: CGFloat = 12
    private let cache = ImageCacheFactory.createDefaultCache()
    @State private var uiImage: UIImage?
    
    var body: some View {
        VStack {
            Spacer()
            if !isExpanded {
                miniPlayer
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                fullPlayer()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(Color.backgroundColor)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isExpanded)
        .task {
            do {
                if let currentSong = self.viewModel.state.currentSong,
                   let data = await cache.get(for: try currentSong.fileURLString()) {
                    if let image = UIImage(data: data) {
                        uiImage = image
                    } else {
                        uiImage = UIImage(named: "demoThumbnail2")
                    }
                    
                } else {
                    uiImage = UIImage(named: "demoThumbnail2")
                }
            } catch {
                uiImage = UIImage(named: "demoThumbnail2")
            }
        }
        .onChange(of: self.viewModel.state.currentSong) { oldValue, newValue in
            Task {
                do {
                    if let currentSong = self.viewModel.state.currentSong,
                       let data = await cache.get(for: try currentSong.fileURLString()) {
                        if let image = UIImage(data: data) {
                            uiImage = image
                        } else {
                            uiImage = UIImage(named: "demoThumbnail2")
                        }
                    } else {
                        uiImage = UIImage(named: "demoThumbnail2")
                    }
                } catch {
                    uiImage = UIImage(named: "demoThumbnail2")
                }
            }
        }
    }
    
    // MARK: - Mini Player View
    private var miniPlayer: some View {
        HStack(spacing: 12) {
            // Album artwork
            if let uiImage = uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .shimmer()
            }
            
            
            // Song info
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.songTitle)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(viewModel.artistName)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Mini controls
            HStack(spacing: 20) {
                Button {
                    viewModel.send(.togglePlay)
                } label: {
                    Image(systemName: viewModel.playButtonIcon)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.black.opacity(0.9))
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: -5)
        )
        .onTapGesture {
            withAnimation {
                isExpanded = true
            }
        }
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    if gesture.translation.height < -50 {
                        withAnimation {
                            isExpanded = true
                        }
                    }
                }
        )
    }
    
    // MARK: - Full Player View
    private func fullPlayer() -> some View {
        GeometryReader { geometry in
            VStack {
                // Custom Navigation Bar
                CustomNavigationBar(type: .custom(title: "",
                                                  left: .init(icon: "chevron.down",
                                                              action: {
                    withAnimation {
                        isExpanded = false
                    }
                }),
                                                  right: .init(icon: "gearshape.fill",
                                                               action: {
                    router.route(to: .showMenuBottomSheet({
                        Task { @MainActor in
                            viewModel.send(.cancelSleepTime)
                            router.dismiss()
                        }
                    }, {
                        Task { @MainActor in
                            router.dismiss()
                            try? await Task.sleep(nanoseconds: 50_000_000) // 0.05s
                            router.route(to: .setSleepTime({ hours, minute, second in
                                Task {
                                    await viewModel.send(.setSleepTime(hours, minute, second))
                                }
                            }))
                        }
                    }))
                })))
                
                Spacer()
                    .frame(height: 16)
                
                // Album artwork
                if let uiImage = uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width * 4 / 5, height: geometry.size.width * 4 / 5)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: geometry.size.width * 4 / 5, height: geometry.size.width * 4 / 5)
                        .shimmer()
                }
                Spacer()
                    .frame(height: 44)
                
                // Song info and controls
                VStack(alignment: .leading) {
                    VStack(spacing: 4) {
                        Text(viewModel.songTitle)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(viewModel.artistName)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundStyle(.white)
                            .font(.system(size: 14))
                    }
                    
                    Spacer()
                        .frame(height: 32)
                    
                    // Progress slider
                    VStack {
                        CustomSliderView(value: $viewModel.state.currentTime,
                                         isDragSliderView: $viewModel.state.isDraging,
                                         minValue: 0,
                                         maxValue: viewModel.state.duration,
                                         trackColor: Color.init(hexString: "#808080"),
                                         progressColor: Color.white) { value in
                            viewModel.send(.seekTo(value))
                        }
                                         .frame(height: 12)
                        
                        HStack {
                            Text(viewModel.currentTimeStr)
                                .foregroundStyle(.white)
                            Spacer()
                            Text(viewModel.state.duration.toTimeString())
                                .foregroundStyle(.white)
                        }
                    }
                    
                    Spacer()
                        .frame(height: 24)
                    
                    // Control buttons
                    HStack {
                        Button {
                            viewModel.send(.changeShuffMode)
                        } label: {
                            Image(systemName: "shuffle")
                                .resizable()
                                .scaledToFit()
                                .aspectRatio(1.0, contentMode: .fit)
                                .foregroundStyle(viewModel.shuffleButtonColor)
                                .frame(width: 28)
                        }
                        
                        Spacer()
                        
                        Button {
                            viewModel.send(.goPrevious)
                        } label: {
                            Image(systemName: "arrowtriangle.backward.fill")
                                .resizable()
                                .scaledToFit()
                                .aspectRatio(1.0, contentMode: .fit)
                                .foregroundStyle(.white)
                                .frame(width: 28)
                        }
                        
                        Spacer()
                        
                        Button {
                            viewModel.send(.togglePlay)
                        } label: {
                            Image(systemName: viewModel.playButtonIcon)
                                .resizable()
                                .scaledToFit()
                                .aspectRatio(1.0, contentMode: .fit)
                                .foregroundStyle(.white)
                                .frame(width: 54)
                        }
                        
                        Spacer()
                        
                        Button {
                            viewModel.send(.goNext)
                        } label: {
                            Image(systemName: "arrowtriangle.right.fill")
                                .resizable()
                                .scaledToFit()
                                .aspectRatio(1.0, contentMode: .fit)
                                .foregroundStyle(.white)
                                .frame(width: 28)
                        }
                        
                        Spacer()
                        
                        Button {
                            viewModel.send(.changeRepeatMode)
                        } label: {
                            Image(systemName: viewModel.repeatButtonIcon)
                                .resizable()
                                .scaledToFit()
                                .aspectRatio(1.0, contentMode: .fit)
                                .foregroundStyle(viewModel.repeatButtonColor)
                                .frame(width: 28)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, geometry.size.width * 1 / 10)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, Helper.shared.safeAreaInsets?.top)
            .background(Color.backgroundColor)
            .gesture(
                DragGesture()
                    .onEnded { gesture in
                        if gesture.translation.height > 100 {
                            withAnimation {
                                isExpanded = false
                            }
                        }
                    }
            )
        }
        
    }
}

// MARK: - Usage Example
struct ContentView: View {
    @State var isExplanded: Bool = false
    var body: some View {
        ZStack {
            // Your main content here
            VStack {
                Spacer()
                Text("Main App Content")
                    .font(.title)
                    .foregroundColor(.white)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.backgroundColor)
            
            // Overlay the collapsible player
            NowPlayingView(isExpanded: $isExplanded)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
