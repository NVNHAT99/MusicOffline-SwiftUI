//
//  CustomNavigtionBar.swift
//  MusicApp
//
//  Created by Nhat on 5/16/23.
//

import SwiftUI

typealias HeaderAction = () -> Void

enum navigationBarType {
    case larger(String)
    case backButton(String)
    case twoButtons(leftAction: HeaderAction?,
                    leftTitle: String?,
                    leftIcon: String?,
                    rightAction: HeaderAction?,
                    rightTitle: String?,
                    rightIcon: String?,
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
            case .twoButtons(let lefAction,
                             let leftTitle,
                             let leftIcon,
                             let rightAction,
                             let rightTitle,
                             let rightIcon,
                             let title):
                setupForTwoButtonsNavi(leftAction: lefAction,
                                       lefTitle: leftTitle ?? String.empty,
                                       leftIcon: leftIcon,
                                       rightAction: rightAction,
                                       rightTitle: rightTitle ?? String.empty,
                                       rightIcon: rightIcon,
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
    
    func setupForTwoButtonsNavi(leftAction: HeaderAction?,
                                lefTitle: String,
                                leftIcon: String? = String.empty,
                                rightAction: HeaderAction?,
                                rightTitle: String,
                                rightIcon: String? = String.empty,
                                title: String) -> some View {
        ZStack {
            VStack {
                Spacer()
                HStack {
                    Button {
                        leftAction?()
                    } label: {
                        HStack(spacing: 2) {
                            if leftIcon != String.empty {
                                Image(systemName: leftIcon ?? String.empty)
                            }
                            Text(lefTitle)
                        }
                        
                    }
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(title)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button {
                        rightAction?()
                    } label: {
                        Text(rightTitle)
                    }
                    .foregroundColor(.white)
                }
                .padding([.leading, .trailing], 15)
                Spacer()
            }
        }
    }
}

struct CustomNavigtionBar_Previews: PreviewProvider {
    static var previews: some View {
        CustomNavigationBar(type: .twoButtons(leftAction: nil
                                              ,leftTitle: "Back",
                                              leftIcon: "chevron.left",
                                              rightAction: nil,
                                              rightTitle: "Add New",
                                              rightIcon: nil,
                                              title: "nothing"))
            .previewLayout(.sizeThatFits)
            .background(Color.backgroundColor)
    }
}
