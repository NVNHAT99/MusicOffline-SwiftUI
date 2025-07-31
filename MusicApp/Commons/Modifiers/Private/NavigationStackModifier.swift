    //
    //  NavigationStackModifier.swift
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

    /// A view modifier that applies a navigation stack to a view, enabling navigation within a SwiftUI application
    /// by utilizing a router that handles navigation logic. This modifier is designed to work across multiple platforms,
    /// including iOS, macOS, tvOS, and watchOS, providing a consistent navigation experience.
    ///
    /// The modifier supports advanced navigation features such as navigation destinations, modal sheets, and full-screen covers,
    /// and integrates with matched geometry effects for smooth transitions between views.
    ///
    /// - Note: This modifier requires iOS 16.0, macOS 13.0, tvOS 16.0, or watchOS 9.0, or later.
    ///
    /// - Parameters:
    ///   - Handler: A type conforming to `RouterHandling`, which is responsible for managing the navigation state and logic.
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    struct NavigationStackModifier<Handler: RouterHandling>: ViewModifier {

        /// The router that manages navigation logic, including navigation paths and presented views.
        @ObservedObject var router: Handler

        /// The namespace for matched geometry transitions, allowing for smooth animations between views.
        private let namespace: Namespace.ID?

        /// Initializes the `NavigationStackModifier` with a router and an optional namespace for transitions.
        /// - Parameters:
        ///   - router: The router responsible for handling the navigation.
        ///   - namespace: An optional namespace used to coordinate matched geometry effects across views.
        init(router: Handler, namespace: Namespace.ID?) {
            self.router = router
            self.namespace = namespace
        }

        /// Constructs the body of the view modifier, applying a navigation stack to the content and configuring navigation behavior.
        /// The body adapts to different platforms, providing appropriate navigation features such as full-screen covers on iOS.
        ///
        /// - Parameter content: The content view to which the navigation stack is applied.
        /// - Returns: A view with the navigation stack applied, along with configured navigation destinations and modal presentations.
        func body(content: Content) -> some View {
            NavigationStack(path: $router.navigationPath) {
                content
                /// Associates a destination view with a specific route type, allowing navigation to different views
                /// based on the current route. This ensures that the correct view is presented when navigating
                /// within the navigation stack.
                    .navigationDestination(for: Handler.Route.self) { route in
                        router
                            .view(for: route)
                            .applyZoomTransition(source: route, namespace: namespace)
                    }
                /// Presents a modal sheet when a route with a `.sheet` presentation style is encountered.
                /// The sheet is dismissed by the user, and a dismiss completion handler can be triggered.
                    .sheet(item: $router.presentedView.convert { $0?.presentationStyle == .sheet ? $0 : nil }) {
                        debugPrint("Sheet dismiss")
                    } content: { route in
                        router
                            .view(for: route)
                            .applyViewPresentation(route: route)
                            .applyZoomTransition(source: route, namespace: namespace)
                    }
    #if os(iOS)
                /// Presents a full-screen cover for iOS when a route with a `.fullScreen` presentation style is encountered.
                /// This view covers the entire screen, providing an immersive experience for content such as video playback
                /// or complex forms. This feature is not available on macOS.
                    .fullScreenCover(item: $router.presentedView.convert { $0?.presentationStyle == .fullScreen ? $0 : nil }) {
                        debugPrint("FullScreenCover dismiss")
                    } content: { route in
                        router
                            .view(for: route)
                            .applyZoomTransition(source: route, namespace: namespace)
                    }
    #endif
            }
        }
    }

    /// Extension to apply the `NavigationStackModifier` to any view, enabling easy integration of navigation
    /// logic into SwiftUI views. This extension provides a convenient way to add a navigation stack with
    /// matched geometry transitions and platform-specific presentation styles.
    ///
    /// - Note: This extension supports iOS 16.0, macOS 13.0, tvOS 16.0, and watchOS 9.0 or later.
    ///
    /// - Parameters:
    ///   - router: The router managing the navigation state and logic.
    ///   - namespace: An optional namespace for matched geometry transitions, enabling coordinated animations.
    /// - Returns: A modified view with the navigation stack applied.
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    extension View {
        func applyNavigationStack<Handler: RouterHandling>(
            with router: Handler,
            namespace: Namespace.ID? = nil
        ) -> some View {
            self.modifier(NavigationStackModifier(router: router, namespace: namespace))
        }
    }
