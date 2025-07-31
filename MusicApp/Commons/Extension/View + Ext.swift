//
//  View + Ext.swift
//  MusicApp
//
//  Created by Nhat on 5/11/23.
//

import Foundation
import SwiftUI

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

extension View {
    /// Áp dụng iOS touch behavior với proper bounds detection, không conflict với ScrollView
    func delaysTouches(
        action: @escaping () -> Void,
        hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle? = .light,
        highlightColor: Color = Color.gray.opacity(0.15),
        scaleEffect: CGFloat = 1.0,
        animationDuration: TimeInterval = 0.1,
        cornerRadius: CGFloat = 0
    ) -> some View {
        self.modifier(DelaysTouches(
            action: action,
            hapticStyle: hapticStyle,
            highlightColor: highlightColor,
            scaleEffect: scaleEffect,
            animationDuration: animationDuration,
            cornerRadius: cornerRadius
        ))
    }
    
    /// Settings row style - không haptic cho toggle
    func settingsRowTouch(action: @escaping () -> Void) -> some View {
        self.delaysTouches(
            action: action,
            hapticStyle: nil, // Không haptic vì toggle tự xử lý
            highlightColor: Color.gray.opacity(0.15),
            scaleEffect: 1.0
        )
    }
    
    /// Navigation row style - có haptic
    func navigationRowTouch(action: @escaping () -> Void) -> some View {
        self.delaysTouches(
            action: action,
            hapticStyle: .light,
            highlightColor: Color.gray.opacity(0.15),
            scaleEffect: 1.0
        )
    }
    
    /// Button style với corner radius
    func buttonTouch(
        action: @escaping () -> Void,
        cornerRadius: CGFloat = 10
    ) -> some View {
        self.delaysTouches(
            action: action,
            hapticStyle: .medium,
            highlightColor: Color.blue.opacity(0.1),
            scaleEffect: 0.96,
            cornerRadius: cornerRadius
        )
    }
    
    /// Card style
    func cardTouch(action: @escaping () -> Void) -> some View {
        self.delaysTouches(
            action: action,
            hapticStyle: .light,
            highlightColor: Color.gray.opacity(0.1),
            scaleEffect: 0.98,
            cornerRadius: 12
        )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
