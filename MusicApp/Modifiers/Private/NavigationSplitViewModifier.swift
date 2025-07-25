//
//  NavigationSplitViewModifier.swift
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

/// A view modifier that applies a navigation split view layout, adapting to different horizontal size classes.
/// This modifier dynamically adjusts the navigation structure based on the available screen size, making it
/// suitable for various devices, from compact screens like phones to larger screens like iPads and MacBooks.
///
/// The modifier supports a flexible sidebar and content layout, using a router to manage navigation and
/// providing a seamless user experience across different platforms. The navigation structure can vary between
/// a `NavigationStack` for compact screens and a `NavigationSplitView` for regular-sized screens.
///
/// - Note: This modifier requires iOS 16.0, macOS 13.0, tvOS 16.0, or watchOS 9.0, or later.
///
/// - Parameters:
///   - Handler: A type conforming to `RouterHandling`, responsible for managing the navigation logic.
///   - SideBar: The type of view used for the sidebar in the split view.
///   - NavContent: The type of view used for the main navigation content in the split view.
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
struct NavigationSplitViewModifier<Handler: RouterHandling, SideBar: View, NavContent: View>: ViewModifier {

    /// The horizontal size class environment value, determining the layout style (compact or regular).
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    /// The router that handles the navigation logic and state management.
    @ObservedObject var router: Handler

    /// The visibility of the split view columns, allowing customization of the split view's appearance.
    @State var columnVisibility: NavigationSplitViewVisibility = .automatic

    /// The namespace for matched geometry effects, enabling smooth transitions between views.
    private let namespace: Namespace.ID?

    /// The view used for the sidebar in the split view.
    private var sidebar: SideBar

    /// The view used for the main navigation content in the split view.
    private var content: NavContent

    /// Initializes the `NavigationSplitViewModifier` with the necessary parameters.
    /// - Parameters:
    ///   - router: The router responsible for handling navigation actions and state.
    ///   - columnVisibility: The visibility of the split view columns, defaulting to `.automatic`.
    ///   - namespace: An optional namespace for matched transitions, allowing for coordinated animations.
    ///   - sidebar: A view builder closure that constructs the sidebar view.
    ///   - content: A view builder closure that constructs the main navigation content view.
    init(
        router: Handler,
        columnVisibility: NavigationSplitViewVisibility,
        namespace: Namespace.ID?,
        @ViewBuilder sidebar: @escaping () -> SideBar,
        @ViewBuilder content: @escaping () -> NavContent
    ) {
        self.router = router
        self.columnVisibility = columnVisibility
        self.namespace = namespace
        self.sidebar = sidebar()
        self.content = content()
    }

    /// Defines the body of the view modifier, applying the appropriate navigation structure based on the screen size.
    /// - Parameter content: The content view to which the navigation split view is applied.
    /// - Returns: A view that incorporates either a `NavigationStack` or a `NavigationSplitView`, depending on the size class.
    func body(content: Content) -> some View {
        switch horizontalSizeClass {
        case .regular:
            self.bodyRegular(with: content, router: router, namespace: namespace)
        default:
            self.bodyCompact(with: content, router: router, namespace: namespace)
        }
    }

    /// Constructs the compact view, typically used for smaller screens like phones, utilizing a `NavigationStack`.
    /// - Parameters:
    ///   - content: The content view to apply the navigation stack to.
    ///   - router: The router managing the navigation logic.
    ///   - namespace: The namespace for matched transitions, enabling animations between views.
    @ViewBuilder
    private func bodyCompact(
        with content: Content,
        router: Handler,
        namespace: Namespace.ID?
    ) -> some View {
        content.applyNavigationStack(with: router, namespace: namespace)
    }

    /// Constructs the regular view, typically used for larger screens like iPads and MacBooks, utilizing a `NavigationSplitView`.
    /// - Parameters:
    ///   - content: The content view to apply the navigation stack to.
    ///   - router: The router managing the navigation logic.
    ///   - namespace: The namespace for matched transitions, enabling animations between views.
    @ViewBuilder
    private func bodyRegular(
        with content: Content,
        router: Handler,
        namespace: Namespace.ID?
    ) -> some View {
        if self.content is EmptyView {
            // When no specific navigation content is provided, use the sidebar and a compact view in the detail.
            NavigationSplitView(columnVisibility: $columnVisibility) {
                self.sidebar
            } detail: {
                self.bodyCompact(with: content, router: router, namespace: namespace)
            }
        } else {
            // When both sidebar and content are provided, use them in the split view.
            NavigationSplitView(columnVisibility: $columnVisibility) {
                self.sidebar
            } content: {
                self.content
            } detail: {
                self.bodyCompact(with: content, router: router, namespace: namespace)
            }
        }
    }
}

extension View {
    /// Applies a navigation split view to the current view, adapting to different size classes and using a router to manage navigation.
    /// This method allows for easy integration of a split view navigation system, with optional sidebar and content views.
    ///
    /// - Parameters:
    ///   - router: The router handling navigation logic.
    ///   - columnVisibility: The visibility of the split view columns, defaulting to `.automatic`.
    ///   - namespace: An optional namespace for matched transitions, providing smooth animations between views.
    ///   - sidebar: A view builder closure that constructs the sidebar view, defaulting to an empty view.
    ///   - content: A view builder closure that constructs the main navigation content view, defaulting to an empty view.
    /// - Returns: A modified view with the navigation split view applied.
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    func applyNavigationSplitView<Handler: RouterHandling, Sidebar: View, Content: View>(
        with router: Handler,
        columnVisibility: NavigationSplitViewVisibility = .automatic,
        namespace: Namespace.ID? = nil,
        @ViewBuilder sidebar: @escaping () -> Sidebar = { EmptyView() },
        @ViewBuilder content: @escaping () -> Content = { EmptyView() }
    ) -> some View {
        self.modifier(
            NavigationSplitViewModifier<Handler, Sidebar, Content>(
                router: router,
                columnVisibility: columnVisibility,
                namespace: namespace,
                sidebar: sidebar,
                content: content
            )
        )
    }
}
