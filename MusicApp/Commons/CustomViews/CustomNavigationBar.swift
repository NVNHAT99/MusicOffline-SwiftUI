//
//  CustomNavigtionBar.swift
//  MusicApp
//
//  Created by Nhat on 5/16/23.
//

import SwiftUI

typealias OnTapAction = () -> Void

enum navigationBarType {
    case larger(String)
    case backButton(String)
    case twoButtons(leftView: (() -> AnyView)?,
                    rightView: (() -> AnyView)?,
                    title: String)
}

struct CustomNavigationBar: View {
    var type: navigationBarType
    var body: some View {
        VStack {
            switch type {
            case .larger(let title):
                setupForLagreNavi(title: title)
            case .backButton(_):
                // i will hanlde this in the future
                EmptyView()
            case .twoButtons(let leftView,
                             let rightView,
                             let title) :
                setupForTwoButtonsNavi(leftView: leftView,
                                       rightView: rightView,
                                       title: title)
                
            }
        }// VStack
    }
    
    func setupForLagreNavi(title: String) -> some View {
        return ZStack {
                    Color.clear
                    Text(title)
                        .font(.largeTitle.weight(.bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
    }
    
    func setupForTwoButtonsNavi(leftView: (() -> AnyView)?,
                                rightView: (() -> AnyView)?,
                                title: String) -> some View {
        ZStack {
            VStack {
                HStack {
                    leftView?() // left header view
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    rightView?() // right header view
                    .foregroundColor(.white)
                }
                .padding([.leading, .trailing], 15)
            }
            
            VStack {
                Text(title)
                    .frame(maxWidth: 250)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
        }
    }
}

struct CustomNavigtionBar_Previews: PreviewProvider {
    static var previews: some View {
        CustomNavigationBar(type: .twoButtons(leftView: nil, rightView: nil, title: ""))
            .previewLayout(.sizeThatFits)
            .background(Color.backgroundColor)
    }
}
