//
//  EmbeddedView.swift
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

/// An enumeration that defines the types of embedded navigation available in a SwiftUI application.
///
/// The `EmbeddedNavigation` enum provides a way to specify different navigation types that can be used
/// to embed views within a navigation container. This includes modern navigation patterns like
/// `NavigationStack` and `NavigationSplitView`, as well as the older `NavigationView`, which has been
/// deprecated in favor of the newer navigation types.
///
/// This enum is particularly useful for creating adaptable user interfaces that can switch between
/// different navigation styles based on the platform or application requirements.
///
/// - Cases:
///   - `stacks`: Represents a `NavigationStack`, available on iOS 16.0, macOS 13.0, tvOS 16.0, and watchOS 9.0, or newer.
///   - `splitView`: Represents a `NavigationSplitView`, also available on iOS 16.0, macOS 13.0, tvOS 16.0, and watchOS 9.0, or newer.
///   - `navigationView`: Represents a `NavigationView`, introduced in iOS 13.0 and macOS 10.15 but deprecated in future versions.
///     It is recommended to use `NavigationStack` or `NavigationSplitView` instead of `NavigationView`.
public enum EmbeddedNavigation {
    /// A navigation stack, available on iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, or newer.
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    case stacks

    /// A navigation split view, available on iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, or newer.
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    case splitView

    /// A navigation view, introduced in iOS 13.0 and macOS 10.15, but deprecated in future versions.
    ///
    /// - Note: The `NavigationView` case is deprecated in favor of the more modern `NavigationStack` and `NavigationSplitView`.
    ///   Use these newer navigation types to ensure compatibility with future versions of iOS and macOS.
    @available(iOS, introduced: 13.0, deprecated: 100000.0, message: "use NavigationStack or NavigationSplitView instead")
    @available(macOS, introduced: 10.15, deprecated: 100000.0, message: "use NavigationStack or NavigationSplitView instead")
    case navigationView
}

public extension View {
    /// Embeds a view within a specified navigation type using a router.
    ///
    /// This method provides a convenient way to embed content within a navigation container, such as
    /// a `NavigationStack` or `NavigationSplitView`, based on the type of navigation specified by the `EmbeddedNavigation` enum.
    /// It also supports modern navigation patterns and allows for easy integration with a router that handles the navigation logic.
    ///
    /// The method supports customization of the sidebar and content views for split view navigation,
    /// as well as optional namespace integration for matched geometry effects.
    ///
    /// - Parameters:
    ///   - navigation: The type of embedded navigation to use, specified by the `EmbeddedNavigation` enum.
    ///   - router: The router that handles the navigation logic, conforming to `RouterHandling`.
    ///   - columnVisibility: The visibility of columns in a split view. The default value is `.automatic`, which lets the system decide.
    ///   - namespace: An optional namespace for matched geometry effects, which can be used to coordinate transitions between views.
    ///   - sidebar: A closure that returns the sidebar view for split view navigation. Defaults to an empty view.
    ///   - content: A closure that returns the content view. Defaults to an empty view.
    /// - Returns: A view embedded in the specified navigation type, allowing for consistent navigation across different parts of the app.
    @ViewBuilder
    func embedded<Handler: RouterHandling, Sidebar: View, Content: View>(
        navigation: EmbeddedNavigation,
        with router: Handler,
        columnVisibility: NavigationSplitViewVisibility = .automatic,
        namespace: Namespace.ID? = nil,
        @ViewBuilder sidebar: @escaping () -> Sidebar = { EmptyView() },
        @ViewBuilder content: @escaping () -> Content = { EmptyView() }
    ) -> some View {
        switch navigation {
        case .splitView:
            /// Embed the content in a NavigationSplitView
            /// Support iPadOS, macOS and iOS
            self.applyNavigationSplitView(
                with: router,
                columnVisibility: columnVisibility,
                namespace: namespace,
                sidebar: sidebar,
                content: content
            )
            
        case .stacks:
            /// Embed the content in a NavigationStack
            /// Support iOS, limit for ipadOS and macOS
            self.applyNavigationStack(
                with: router,
                namespace: namespace
            )

        case .navigationView:
            /// Fallback for older navigation view; recommended to use NavigationStack or NavigationSplitView
            // TODO: - support for iOS below 16 later
            self
        }
    }

    /// Adds a modifier to read the height of the view.
    ///
    /// This method allows a view to report its height, enabling other parts of the UI to react to size changes.
    /// The height is captured using a custom view modifier and reported back through the provided completion closure.
    ///
    /// - Parameter completion: A closure that is executed whenever the height of the view changes, passing the new height as a parameter.
    /// - Returns: A modified view that performs the specified action whenever the height changes.
    func readHeight(
        _ completion: @escaping (CGFloat) -> Void
    ) -> some View {
        self.modifier(ReadHeightModifier())
            .onPreferenceChange(
                HeightPreferenceKey.self,
                perform: completion
            )
    }
}
