//
//  RouterHandling.swift
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

/// A protocol that defines the essential functionalities for a router in a SwiftUI application,
/// enabling structured navigation, view management, and routing within the app.
///
/// The `RouterHandling` protocol integrates several key capabilities, including managing a stack of routes,
/// handling the presentation and dismissal of views, and coordinating navigation between different parts
/// of the application. By conforming to this protocol, a router can seamlessly manage both navigation paths
/// and modal presentations, providing a consistent and organized approach to navigation in SwiftUI.
///
/// The protocol is designed to work with any type that conforms to `Routable`, ensuring that the router
/// can handle any route that fits within the defined navigation structure. It also requires conformance
/// to `ObservableObject`, enabling the router to be observed for changes, and `Sendable`, ensuring safe
/// usage in concurrent contexts.
///
/// - Associated Types:
///   - `Route`: The type of route that the router will handle, conforming to `Routable`.
///   - `V`: The type of view that the router will provide for a given route.
///
/// - Properties:
///   - `navigationPath`: A `NavigationPath` representing the current stack of routes, allowing for push and pop navigation operations.
///   - `presentedView`: The currently presented route, if any, representing a view that is shown modally (e.g., as a sheet or full-screen cover).
///   - `presentingRouter`: The router that presented the current router, if any, enabling nested routing and navigation flows.
@MainActor
public protocol RouterHandling: ObservableObject, Sendable {
    associatedtype Route: Routable
    associatedtype V: View

    /// The navigation path representing the current stack of routes.
    ///
    /// This property is a sequence of routes that the user has navigated through using navigation links.
    /// It is used to manage push and pop operations within the navigation stack, allowing for structured navigation flows.
    var navigationPath: NavigationPath { get set }

    /// The currently presented route, if any.
    ///
    /// This property holds the route that is currently presented using a modal presentation style, such as a sheet
    /// or full-screen cover. The view associated with this route is shown on top of the current navigation stack.
    var presentedView: Route? { get set }

    /// The router that presented the current router, if any.
    ///
    /// This property holds a reference to the router that presented the current router, allowing for nested navigation stacks.
    /// It is useful for managing complex navigation flows where one router may present another as part of the application's structure.
    var presentingRouter: Self? { get set }

    /// Routes to a given route asynchronously.
    ///
    /// This method handles navigation to a new route. Depending on the route's presentation style, the method
    /// either appends the route to the navigation path (for navigation links) or sets it as the currently presented view
    /// (for sheets or full-screen presentations). If a `dismissCompletion` closure is provided, it will be executed
    /// upon the dismissal of the presented route.
    ///
    /// - Parameter route: The route to navigate to.
    /// - Parameter dismissCompletion: An optional closure to be executed when the route is dismissed. This is currently
    ///   applicable only to routes with `.sheet` or `.fullScreen` presentation styles.
    func route(to route: Route, dismissCompletion: (() -> Void)?)

    func portal(for portalRoute: any PortalRoute, dismissCompletion: (() -> Void)?)

    /// Provides the view for a given route.
    ///
    /// This method returns the view associated with the specified route, attaching the appropriate router
    /// to handle any further navigation actions within that view.
    ///
    /// - Parameter route: The route for which the view is provided.
    /// - Returns: The view associated with the route.
    func view(for route: Route) -> V

    /// Dismisses the currently presented view asynchronously.
    ///
    /// This method handles the dismissal of the currently presented view, such as a sheet or full-screen cover,
    /// and resets the `presentedView` property. If a `dismissCompletion` closure is set, it will be executed
    /// after the view is dismissed.
    func dismiss()

    /// Dismisses all presented views asynchronously.
    ///
    /// This method recursively dismisses all presented views, ensuring that the entire stack of modally presented
    /// views is cleared. It is useful for returning to a base state in the app, where no modally presented views remain.
    func dismissAll()

    /// Pops to the root of the navigation stack asynchronously.
    ///
    /// This method removes all routes from the navigation path, returning the navigation stack to its root state.
    /// It is used to navigate back to the starting point of the navigation stack, effectively resetting the navigation history.
    func popToRoot()

    /// Pops the last view from the navigation stack asynchronously.
    ///
    /// This method removes the last route from the navigation path, effectively navigating back one step in the stack.
    /// It is used to undo the last navigation action, returning to the previous route in the stack.
    func pop()

    /// Counts the number of routers in the stack.
    ///
    /// This method counts how many routers are in the stack, including the current router and any presenting routers.
    /// It is useful for determining the depth of nested navigation stacks, which can inform decisions about navigation flow.
    ///
    /// - Returns: The number of routers in the stack.
    func stacksCount() -> Int
}

public extension RouterHandling {
    /// Routes to a given route asynchronously with an optional dismiss completion.
    ///
    /// This extension provides a default implementation of the `route(to:dismissCompletion:)` method, allowing
    /// for the `dismissCompletion` parameter to be optional. This simplifies the API, making it easier to use
    /// the `route(to:)` method without always requiring a completion handler.
    ///
    /// - Parameter route: The route to navigate to.
    /// - Parameter dismissCompletion: An optional closure to be executed when the route is dismissed. Defaults to `nil`.
    func route(to route: Route, dismissCompletion: (() -> Void)? = nil) {
        self.route(to: route, dismissCompletion: dismissCompletion)
    }

    func portal(for portalRoute: any PortalRoute, dismissCompletion: (() -> Void)? = nil) {
        self.portal(for: portalRoute, dismissCompletion: dismissCompletion)
    }
}
