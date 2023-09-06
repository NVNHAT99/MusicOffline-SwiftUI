//
//  PlaysongView.swift
//  MusicApp
//
//  Created by Nhat on 8/22/23.
//

import SwiftUI
import Combine

struct PlaySongView: View {
    // MARK: - PROPERTIES WRAPER
    @ObservedObject var viewModel: PlaySongHandler
    var body: some View {
        GeometryReader { proxy in
            VStack  {
                Spacer()
                    .frame(height: 24)
                Image("templePlaylist")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width == 0 ? 0 : proxy.size.width - 32,
                           height: (proxy.size.height * 2) / 3)
                    .background(.red)
                    .clipped().cornerRadius( 16, corners: .allCorners)
                Text("ten bai hat o day")
                Spacer()
                    .frame(height: 20)
                VStack (spacing: 0) {
                    CustomSliderView(value: viewModel.sliderValue(),
                                     trackHeight: 6,
                                     minValue: 0,
                                     maxValue: viewModel.state.duration,
                                     trackColor: .gray.opacity(0.3),
                                     progressColor: .white)
                    .frame(height: 6)
                    HStack {
                        Text("2:47")
                        Spacer()
                        Text("-1:13")
                    }
                    .foregroundColor(.white)
                    .padding(.top, 4)
                }
                
                Spacer()
                    .frame(height: 40)
                HStack {
                    Button {
                        
                    } label: {
                        Image(systemName: "clock")
                            .iconModifer(size: CGSize(width: 20, height: 20))
                    }
                    
                    Spacer()
                    Button {
                        
                    } label: {
                        Image(systemName: "arrowtriangle.left.fill")
                            .iconModifer(size: CGSize(width: 24, height: 24))
                    }
                    Spacer()
                    Button {
                        if viewModel.state.isPlaying {
                            viewModel.send(intent: .pause)
                        } else {
                            viewModel.send(intent: .play)
                        }
                    } label: {
                        let imageName = viewModel.state.isPlaying ? "pause.circle.fill" : "play.circle.fill"
                        Image(systemName: imageName)
                            .iconModifer(size: CGSize(width: 48, height: 48))
                    }
                    Spacer()
                    Button {
                        
                    } label: {
                        Image(systemName: "arrowtriangle.right.fill")
                            .iconModifer(size: CGSize(width: 24, height: 24))
                    }
                    Spacer()
                    Button {
                        
                    } label: {
                        Image(systemName: "repeat")
                            .iconModifer(size: CGSize(width: 20, height: 20))
                    }
                } // Hstack
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                Spacer()
                    
            } // VStack
            .padding(.horizontal, 16)
            .background(Color.backgroundColor)
        } // geometry
    }
}

struct PlaysongView_Previews: PreviewProvider {
    static var previews: some View {
        PlaySongView(viewModel: PlaySongHandler(playVM: PlayViewModel()))
    }
}
