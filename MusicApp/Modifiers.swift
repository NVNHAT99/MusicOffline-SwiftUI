//
//  Modifiers.swift
//  MusicApp
//
//  Created by Nhat on 6/14/23.
//

import Foundation
import SwiftUI
import UIKit

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

// MARK: - TouchTrackingView để handle touch bounds detection
class TouchTrackingView: UIView {
    var onTouchBegan: (() -> Void)?
    var onTouchMoved: ((Bool) -> Void)? // isInsideBounds
    var onTouchEnded: ((Bool) -> Void)? // isInsideBounds
    var onTouchCancelled: (() -> Void)?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        onTouchBegan?()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let isInside = bounds.contains(location)
        onTouchMoved?(isInside)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let isInside = bounds.contains(location)
        onTouchEnded?(isInside)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        onTouchCancelled?()
    }
}

// MARK: - TouchTrackingRepresentable
struct TouchTrackingRepresentable: UIViewRepresentable {
    let onTouchBegan: () -> Void
    let onTouchMoved: (Bool) -> Void
    let onTouchEnded: (Bool) -> Void
    let onTouchCancelled: () -> Void
    
    func makeUIView(context: Context) -> TouchTrackingView {
        let view = TouchTrackingView()
        view.backgroundColor = UIColor.clear
        view.onTouchBegan = onTouchBegan
        view.onTouchMoved = onTouchMoved
        view.onTouchEnded = onTouchEnded
        view.onTouchCancelled = onTouchCancelled
        return view
    }
    
    func updateUIView(_ uiView: TouchTrackingView, context: Context) {
        uiView.onTouchBegan = onTouchBegan
        uiView.onTouchMoved = onTouchMoved
        uiView.onTouchEnded = onTouchEnded
        uiView.onTouchCancelled = onTouchCancelled
    }
}

// MARK: - DelaysTouches Modifier với UIKit touch tracking
struct DelaysTouches: ViewModifier {
    let action: () -> Void
    let hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle?
    let highlightColor: Color
    let scaleEffect: CGFloat
    let animationDuration: TimeInterval
    let cornerRadius: CGFloat
    
    @State private var isPressed = false
    @State private var shouldShowHighlight = false
    @State private var isTouchActive = false
    
    init(
        action: @escaping () -> Void,
        hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle? = .light,
        highlightColor: Color = Color.gray.opacity(0.15),
        scaleEffect: CGFloat = 1.0,
        animationDuration: TimeInterval = 0.1,
        cornerRadius: CGFloat = 0
    ) {
        self.action = action
        self.hapticStyle = hapticStyle
        self.highlightColor = highlightColor
        self.scaleEffect = scaleEffect
        self.animationDuration = animationDuration
        self.cornerRadius = cornerRadius
    }
    
    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .background(
                // Highlight background
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(shouldShowHighlight ? highlightColor : Color.clear)
                    .animation(.easeOut(duration: animationDuration), value: shouldShowHighlight)
            )
            .scaleEffect(isPressed ? scaleEffect : 1.0)
            .animation(.easeInOut(duration: animationDuration), value: isPressed)
            .overlay(
                // Invisible touch tracking overlay
                TouchTrackingRepresentable(
                    onTouchBegan: {
                        handleTouchBegan()
                    },
                    onTouchMoved: { isInsideBounds in
                        handleTouchMoved(isInsideBounds: isInsideBounds)
                    },
                    onTouchEnded: { isInsideBounds in
                        handleTouchEnded(isInsideBounds: isInsideBounds)
                    },
                    onTouchCancelled: {
                        handleTouchCancelled()
                    }
                )
            )
    }
    
    private func handleTouchBegan() {
        isTouchActive = true
        
        withAnimation(.easeInOut(duration: animationDuration)) {
            isPressed = true
            shouldShowHighlight = true
        }
        
        // Haptic feedback khi bắt đầu touch
        if let hapticStyle = hapticStyle {
            let impactFeedback = UIImpactFeedbackGenerator(style: hapticStyle)
            impactFeedback.impactOccurred()
        }
    }
    
    private func handleTouchMoved(isInsideBounds: Bool) {
        guard isTouchActive else { return }
        
        if !isInsideBounds && isPressed {
            // Touch moved outside bounds
            withAnimation(.easeOut(duration: animationDuration)) {
                shouldShowHighlight = false
                isPressed = false
            }
        } else if isInsideBounds && !isPressed {
            // Touch moved back inside bounds
            withAnimation(.easeInOut(duration: animationDuration)) {
                isPressed = true
                shouldShowHighlight = true
            }
        }
    }
    
    private func handleTouchEnded(isInsideBounds: Bool) {
        guard isTouchActive else { return }
        isTouchActive = false
        
        // Trigger action chỉ khi touch kết thúc trong bounds
        if isPressed && isInsideBounds {
            action()
        }
        
        // Reset pressed state
        withAnimation(.easeOut(duration: animationDuration)) {
            isPressed = false
        }
        
        // Delay fade out highlight
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            withAnimation(.easeOut(duration: animationDuration)) {
                shouldShowHighlight = false
            }
        }
    }
    
    private func handleTouchCancelled() {
        guard isTouchActive else { return }
        isTouchActive = false
        
        // Reset tất cả states khi touch bị cancelled
        withAnimation(.easeOut(duration: animationDuration)) {
            isPressed = false
            shouldShowHighlight = false
        }
    }
}

