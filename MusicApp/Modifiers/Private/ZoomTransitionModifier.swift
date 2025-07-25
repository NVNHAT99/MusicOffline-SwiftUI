//
//  ZoomTransitionModifier.swift
//  MVICore
//
//  Created by Nguyen Thanh Sang (thnhsng) on 17/7/24.
//
//  Copyright © 2024 Nguyen Thanh Sang. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
//  documentation files (the "Software"), to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
//  and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
//  THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
//  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import SwiftUI

#warning(" ⚠️ TODO: - This is not stable yet. will update soon.")

/// A view modifier that applies a zoom transition to a view, enabling smooth visual transitions
/// between different states or views within a SwiftUI application. This modifier leverages the
/// matched geometry effect to create a visually appealing transition between source and destination views.
///
/// The modifier is designed to work across multiple platforms, including iOS, macOS, tvOS, watchOS, and visionOS.
/// Depending on the platform, the transition may vary, ensuring compatibility and a native look and feel on each platform.
///
/// - Note: This modifier is available starting from iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, and visionOS 2.0.
///
/// - Parameters:
///   - Transition: A type conforming to `ZoomTransition`, which defines the transition's configuration and behavior.
@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
struct TransitionModifier<Transition: ZoomTransition>: ViewModifier {

    /// The configuration for the zoom transition, containing details like the source ID and other properties
    /// that define how the transition should behave.
    private let transition: Transition

    /// The namespace used for the matched geometry effect, allowing for coordinated animations
    /// between views that share the same namespace.
    private let namespace: Namespace.ID

    /// Initializes the `TransitionModifier` with a transition configuration and a namespace for the transition.
    /// - Parameters:
    ///   - source: The transition configuration, defining how the zoom transition should behave.
    ///   - namespace: The namespace used for the matched geometry effect, ensuring smooth transitions between views.
    init(source: Transition, namespace: Namespace.ID) {
        self.transition = source
        self.namespace = namespace
    }

    /// Defines the body of the view modifier, applying the zoom transition based on the platform.
    /// This method conditionally applies different transition effects depending on whether the platform
    /// supports UIKit (iOS) or AppKit (macOS).
    ///
    /// - Parameter content: The content view to which the transition is applied.
    /// - Returns: A view modified with the zoom transition, or another appropriate transition based on the platform.
    func body(content: Content) -> some View {
#if canImport(UIKit)
        // For platforms that support UIKit (iOS, visionOS, etc.), apply a navigation transition using a zoom effect.
        content
            .navigationTransition(
                .zoom(sourceID: transition.sourceID, in: namespace)
            )
#elseif canImport(AppKit)
        // For platforms that support AppKit (macOS), apply a scale and opacity transition.
        content
            .transition(AnyTransition.scale.combined(with: .opacity))
#else
        content
#endif
    }
}

extension View {
    /// Applies a zoom transition to the view using the specified route and namespace.
    /// This method simplifies the application of a `TransitionModifier`, making it easy to add
    /// zoom transitions to views within a SwiftUI application.
    ///
    /// - Parameters:
    ///   - source: A type conforming to `Routable`, providing the source configuration for the transition.
    ///   - namespace: The namespace used for the matched geometry effect, allowing coordinated animations.
    /// - Returns: A view modified with the zoom transition if the platform and conditions are met; otherwise, returns the original view.
    @ViewBuilder
    func applyZoomTransition<Route: Routable>(
        source: Route,
        namespace: Namespace.ID?
    ) -> some View {
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *),
           let namespace, source.sourceID != nil {
            self.modifier(TransitionModifier(source: source, namespace: namespace))
        } else {
            self
        }
    }

    /// Sets the view as a source for a matched transition using the specified route and namespace.
    /// This method configures the view to participate in a matched geometry effect, creating a smooth
    /// visual transition from one view to another, especially when navigating between screens or states.
    ///
    /// - Parameters:
    ///   - source: A type conforming to `ZoomTransition`, providing the source configuration for the transition.
    ///   - namespace: The namespace used for the matched geometry effect, ensuring coordinated animations.
    /// - Returns: A view modified as a matched transition source, or the original view if conditions are not met.
    @ViewBuilder
    public func matchedTransitionSource<Route: ZoomTransition>(
        source: Route,
        namespace: Namespace.ID?
    ) -> some View {
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *),
           let namespace, source.sourceID != nil {
#if canImport(AppKit)
            // For macOS, apply a matched geometry effect using the source ID.
            self.matchedGeometryEffect(id: source.sourceID, in: namespace)
#else
            // For other platforms, use a matched transition source with a clear background for the transition.
            self.matchedTransitionSource(id: source.sourceID, in: namespace) {
                $0.background(.clear)
            }
#endif
        } else {
            self
        }
    }
}
