//
//  Router.swift
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

import Combine
import SwiftUI

/// A final class that implements the `RouterHandling` protocol, providing navigation and routing capabilities
/// for SwiftUI applications. The `Router` class is designed to manage navigation paths, present views, and handle
/// dismissals and transitions between different routes in a structured and asynchronous manner.
///
/// This router class is intended to work with routes that conform to the `Routable` protocol, allowing for a
/// consistent approach to navigation within the application. The router handles different presentation styles,
/// such as navigation links, sheets, and full-screen presentations, and can also manage nested routers when
/// transitioning between different parts of the app.
///
/// - Note: The `Router` class is annotated with `@MainActor`, ensuring that all its operations are performed on the main thread,
/// which is critical for maintaining UI consistency in SwiftUI.
///
/// - Parameters:
///   - Route: A type that conforms to `Routable`, representing the various routes that can be navigated to within the app.
@MainActor
public final class Router<Route: Routable>: RouterHandling {
    /// The navigation path representing the current stack of routes.
    ///
    /// This path tracks the sequence of routes that the user has navigated through using `NavigationLink`.
    /// The navigation path is published, meaning that any changes to the path will automatically update
    /// any views that are observing this router, enabling reactive UI updates.
    @Published public var navigationPath: NavigationPath

    /// The currently presented route, if any.
    ///
    /// This property holds the route that is currently presented using a modal presentation style, such as a sheet
    /// or a full-screen cover. It is published, so changes to the presented view will trigger UI updates.
    @Published public var presentedView: Route?

    /// A closure that is executed when a presented view is dismissed.
    ///
    /// This optional closure can be used to perform any cleanup or additional actions after a view has been dismissed.
    public var dismissCompletion: (() -> Void)?

    /// The router that presented the current router, if any.
    ///
    /// This property holds a reference to the router that presented the current router. This is useful for managing
    /// nested navigation stacks, where one router may present another as part of a larger navigation flow.
    public weak var presentingRouter: Router?

    /// Dictionary to map route identifiers to their RouteState.
    ///
    /// This dictionary stores the state associated with each route, including any dismiss completion handlers.
    /// It is used to manage the lifecycle of routes and ensure that appropriate actions are taken when a route is dismissed.
    private var routeStates: [String: RouteState<Route>] = [:]

    private var portalMapper: (any PortalRouteMappable)?

    /// Initializes a new `Router` instance.
    ///
    /// - Parameters:
    ///   - path: The initial navigation path, defaulting to an empty path if not provided.
    ///   - presentingRouter: The router that presented this router, if any. This is typically used for nested navigation stacks.
    public init(
        path: NavigationPath = .init(),
        presentingRouter: Router? = nil,
        portalMapper: (any PortalRouteMappable)? = nil
    ) {
        self.navigationPath = path
        self.presentingRouter = presentingRouter
        self.portalMapper = portalMapper
    }

    /// Routes to a given route asynchronously based on its presentation style.
    ///
    /// This method handles navigation to a new route. Depending on the route's presentation style, the method
    /// either appends the route to the navigation path (for navigation links) or sets it as the currently presented view
    /// (for sheets or full-screen presentations). If a `dismissCompletion` closure is provided, it is associated with the route
    /// and invoked when the route is dismissed.
    ///
    /// - Parameter route: The route to navigate to.
    /// - Parameter dismissCompletion: An optional closure to be executed when the route is dismissed. This is currently
    ///   applicable only to routes with `.sheet` or `.fullScreen` presentation styles.
    public func route(to route: Route, dismissCompletion: (() -> Void)? = nil) {
        registerRouteState(for: route, dismissCompletion: dismissCompletion)

        switch route.presentationStyle {
        case .navigationLink:
            navigationPath.append(route)
        case .sheet, .fullScreen:
            presentedView = route
        }
    }

    public func portal(for portalRoute: any PortalRoute, dismissCompletion: (() -> Void)? = nil) {
        portalMapper?.portalRoute(for: portalRoute)
    }

    /// Provides the view for a given route.
    ///
    /// This method returns the view associated with the specified route, attaching the appropriate router
    /// to handle any further navigation actions within that view.
    ///
    /// - Parameter route: The route for which the view is provided.
    /// - Returns: The view associated with the route.
    @ViewBuilder
    public func view(for route: Route) -> some View {
        route.view(attach: self.router(from: route))
    }

    /// Dismisses the currently presented view asynchronously.
    ///
    /// This method handles the dismissal of the currently presented view, such as a sheet or full-screen cover,
    /// and resets the `presentedView` property. If a `dismissCompletion` closure is set, it will be executed
    /// after the view is dismissed.
    public func dismiss() {
        if let presentedRoute = presentingRouter?.presentedView {
            invokeAndRemoveDismissCompletion(for: presentedRoute)
        }
        dismissPresentingView()
        presentedView = nil
    }

    /// Dismisses all presented views asynchronously, including any nested routers.
    ///
    /// This method recursively dismisses all presented views until the entire stack is empty, ensuring that
    /// all nested views are properly dismissed.
    public func dismissAll() {
        presentingRouter?.dismiss()
    }

    /// Pops to the root of the navigation stack asynchronously.
    ///
    /// This method removes all routes from the navigation path, returning the navigation stack to its root state.
    /// If the stack is already empty, an error message is printed.
    ///
    /// TODO: - popCompletion: A future enhancement (currently commented out) that will allow routes to have a completion handler
    public func popToRoot() {
        guard !navigationPath.isEmpty else {
            debugPrint("Error: No items to pop")
            return
        }
        navigationPath.removeLast(navigationPath.count)
    }

    /// Pops the last view from the navigation stack asynchronously.
    ///
    /// This method removes the last route from the navigation path, effectively navigating back one step.
    /// If the stack is empty, an error message is printed.
    ///
    /// TODO: - popCompletion: A future enhancement (currently commented out) that will allow routes to have a completion handler
    public func pop() {
        guard !navigationPath.isEmpty else {
            debugPrint("Error: No items to pop")
            return
        }
        navigationPath.removeLast()
    }

    /// Counts the number of routers in the stack.
    ///
    /// This method counts how many routers are in the stack, including the current router and any presenting routers.
    /// It is useful for determining the depth of nested navigation stacks.
    ///
    /// - Returns: The number of routers in the stack.
    public func stacksCount() -> Int {
        sequence(first: presentingRouter) {
            $0?.presentingRouter
        }.reduce(0) { count, _ in count + 1 }
    }
}

// MARK: - Private

private extension Router {
    /// Dismisses the presenting view by clearing the presented view and the presenting router.
    ///
    /// This method is used internally to reset the state of the presenting router when a view is dismissed.
    private func dismissPresentingView() {
        presentingRouter?.presentedView = nil
        presentingRouter = nil
    }

    /// Gets the appropriate router for the given route based on its presentation style.
    ///
    /// This method returns either the current router or a new router depending on the route's presentation style.
    /// For navigation links, the current router is returned. For sheets or full-screen presentations, a new router is created.
    ///
    /// - Parameter route: The route for which the router is needed.
    /// - Returns: The appropriate router for handling the route.
    private func router(from route: Route) -> Router {
        switch route.presentationStyle {
        case .navigationLink: return self
        case .sheet, .fullScreen: return .init(presentingRouter: self, portalMapper: self.portalMapper)
        }
    }
}

// MARK: - RouteState / DismissCompletion

private extension Router {
    /// Registers a new route state with the router.
    ///
    /// This method stores the state associated with a route, including any dismiss completion handlers.
    /// The route state is stored in a dictionary keyed by the route's identifier.
    ///
    /// - Parameter route: The route for which the state is being registered.
    /// - Parameter dismissCompletion: An optional closure that will be invoked when the route is dismissed.
    private func registerRouteState(for route: Route, dismissCompletion: (() -> Void)?) {
        let routeState = RouteState(
            route: route,
            dismissCompletion: dismissCompletion,
            popCompletion: dismissCompletion
        )
        let routeKey = String(describing: route)
        routeStates[routeKey] = routeState
    }

    /// Invokes and removes the dismiss completion handler for a given route.
    ///
    /// This method is used to invoke the dismiss completion handler associated with a route and then remove
    /// the route's state from the router. It is typically called when a route is dismissed.
    ///
    /// - Parameter route: The route for which the dismiss completion handler should be invoked.
    private func invokeAndRemoveDismissCompletion(for route: Route?) {
        guard let route = route else { return }
        let routeKey = String(describing: route)

        if let routeState = presentingRouter?.routeStates[routeKey] {
            routeState.dismissCompletion?() // Invoke the completion
            presentingRouter?.routeStates.removeValue(forKey: routeKey) // Remove the route state
        }
    }
}

@MainActor
protocol NavigationActionHandler {
    func popView()
    func dismissView()
}

extension Router: NavigationActionHandler {
    func popView() {
        self.pop()
    }
    
    func dismissView() {
        self.dismiss()
    }
}
