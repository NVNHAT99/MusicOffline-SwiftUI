//
//  SwiftUIView.swift
//  MusicApp
//
//  Created by Nhat on 9/14/23.
//

import SwiftUI
import Foundation

struct SwiperToDeleteView<Content: View>: View {
    @State private var offset = CGSize.zero
    @State private var isDragEnd: Bool = false
    @ViewBuilder let content: Content
    var deleteAction: (() -> Void)
    let valueDelete: Double = 0.9
    @State var isDeleteActionCalled: Bool = false
    
    var body: some View {
        GeometryReader { proxy in
            if !isDeleteActionCalled {
                VStack {
                    ZStack(alignment: .leading) {
                        HStack {
                            let percent = abs(offset.width) / proxy.size.width
                            let width: Double = percent > 0.8 ? 100 : 2
                            let alignment: Alignment = percent > 0.8 ? .leading : .trailing
                            let textWidth: Double = abs(proxy.size.width - 8)
                            Spacer()
                                .frame(width: width)
                            Text("Delete")
                                .padding(.horizontal, 8)
                                .frame(width: textWidth,height: proxy.size.height, alignment: alignment)
                                .onTapGesture {
                                    if !isDeleteActionCalled {
                                        withAnimation {
                                            self.offset.width = -proxy.size.width
                                            deleteAction()
                                            isDeleteActionCalled = true
                                        }
                                    }
                                }
                        } // HStack: the deleteView
                        .background(.red)
                        // MARK: - ContentView
                        content
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .offset(x: offset.width, y: 0)
                            .gesture(
                                DragGesture()
                                    .onChanged { gesture in
                                        if gesture.translation.width <= 0 {
                                            if !isDragEnd {
                                                self.offset = gesture.translation
                                            } else {
                                                self.offset.width = gesture.translation.width - 64
                                            }
                                        } else {
                                            self.offset.width = min(gesture.translation.width, 0)
                                        }
                                        
                                        let percent = abs(self.offset.width) / proxy.size.width
                                        if percent >= valueDelete {
                                            if !isDeleteActionCalled {
                                                withAnimation {
                                                    self.offset.width = -proxy.size.width
                                                    deleteAction()
                                                    isDeleteActionCalled = true
                                                }
                                            }
                                        }
                                    }
                                    .onEnded({ gesture in
                                        if self.offset.width != 0 {
                                            self.offset.width = -64
                                            isDragEnd = true
                                        } else {
                                            isDragEnd = false
                                        }
                                        
                                    })
                            )
                            .animation(.easeInOut, value: offset)
                    } // ZStack
                } // VStack
                .clipped()
                .transition(.move(edge: .leading))
            }
        }
    }
}

struct SwiperToDeleteView_Previews: PreviewProvider {
    static var previews: some View {
        SwiperToDeleteView() {
            HStack {
                Spacer()
                Text("thoi nao")
                Spacer()
            }
            .background(.blue)
        } deleteAction: {
            
        }
        .frame(height: 50)

    }
}
