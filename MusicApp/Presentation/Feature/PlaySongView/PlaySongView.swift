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
    @ObservedObject var viewModel: PlaySongViewModel
    @State var isPresented: Bool = false
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                VStack {
                    Spacer()
                        .frame(height: 24)
                    Image(uiImage: viewModel.wrapperImage())
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width == 0 ? 0 : proxy.size.width - 32,
                               height: (proxy.size.height * 2) / 3)
                        .clipped().cornerRadius( 16, corners: .allCorners)
                    Spacer()
                        .frame(height: 20)
                    Text(viewModel.state.song?.name ?? String.empty)
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                        .lineLimit(1)
                        .frame(width: 300)
                    Spacer()
                        .frame(height: 20)
                    VStack (spacing: 0) {
                        CustomSliderView(value: viewModel.sliderValue(),
                                         isDragSliderView: viewModel.isDrag(),
                                         trackHeight: 6,
                                         minValue: 0,
                                         maxValue: viewModel.state.song?.duration ?? 0,
                                         trackColor: .gray.opacity(0.3),
                                         progressColor: .white,
                                         onCompletedDrag: { value in
                            viewModel.send(intent: .updateRunning(newTime: value))
                        })
                        .frame(height: 12)
                        HStack {
                            Text(viewModel.convertTime(input: Int(viewModel.state.currentTimePlaying)))
                            Spacer()
                            Text(viewModel.convertTime(input: Int(viewModel.state.song?.duration ?? 0)))
                        }
                        .foregroundColor(.white)
                        .padding(.top, 4)
                    }
                    
                    Spacer()
                        .frame(height: 40)
                    HStack {
                        Button {
                            withAnimation {
                                isPresented = true
                            }
                        } label: {
                            Image(systemName: "clock")
                                .iconModifer(size: CGSize(width: 16, height: 16))
                        }
                        
                        Spacer()
                        Button {
                            viewModel.send(intent: .previusSong)
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
                            viewModel.send(intent: .nextSong)
                        } label: {
                            Image(systemName: "arrowtriangle.right.fill")
                                .iconModifer(size: CGSize(width: 24, height: 24))
                        }
                        Spacer()
                        Button {
                            viewModel.send(intent: .stateRepeat)
                        } label: {
                            Image(systemName: viewModel.wrapRepeatIcon())
                                .iconModifer(size: CGSize(width: 16, height: 16))
                        }
                    } // Hstack
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    Spacer()
                        
                } // VStack
                .padding(.horizontal, 16)
                .background(Color.black)
            }
            
            .overlay(alignment: .bottom, content: {
                if isPresented {
                    TimeOffView { value in
                        if let value = value {
                            viewModel.send(intent: .timeTurnOff(time: value))
                        }
                        withAnimation {
                            isPresented = false
                        }
                    }
                    .transition(.move(edge: .bottom))
                } else if viewModel.state.isShowToastView {
                    ToastView(isShowView: viewModel.isShowToastView(), message: viewModel.state.toastViewMessage, timeShowView: .seconds(2))
                        .frame(height: 40)
                        .padding(.bottom, 24)
                }
            })
            .edgesIgnoringSafeArea(.bottom)
        } // geometry
    }
}

struct PlaysongView_Previews: PreviewProvider {
    static var previews: some View {
        PlaySongView(viewModel: PlaySongViewModel())
    }
}
