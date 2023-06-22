//
//  Modifiers.swift
//  MusicApp
//
//  Created by Nhat on 6/14/23.
//

import Foundation
import SwiftUI

struct CustomModifiers {
    struct PushContentKeyboardModifier: ViewModifier {
        @Binding var heightOfKeyboard: CGFloat
        let offsetYOfView: CGFloat
        let isPresented: Bool
        func body(content: Content) -> some View {
            content
                .offset(y: -heightOfKeyboard)
                .animation(.easeInOut(duration: 0.3), value: heightOfKeyboard)
                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
                    guard let userInfo = notification.userInfo else { return }
                    guard let keyboardSize = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
                    
                    let keyboardFrameInWindow = keyboardSize.intersection(UIScreen.main.bounds)
                    
                    if keyboardFrameInWindow.height == 0 {
                        heightOfKeyboard = 0
                    } else {
                        let offsetYKeyBoard = keyboardFrameInWindow.minY + (Helper.shared.safeAreaInsets?.bottom ?? 0)
                        let newOffsetYView = isPresented ? (offsetYOfView - 10.5) : offsetYOfView
                        let keyboardOffset = max(offsetYKeyBoard - newOffsetYView, 0) + 20
                        heightOfKeyboard = keyboardOffset
                    }
                }
        }
    }
}
