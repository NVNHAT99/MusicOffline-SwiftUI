//
//  RouteState.swift
//  MVICore
//
//  Created by Nguyen Thanh Sang (thnhsng) on 10/8/24.
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

/// A structure that encapsulates the state of a route, including its associated completion handlers.
///
/// `RouteState` is used to manage the lifecycle of a route within the `Router` class. It holds a reference to the route itself,
/// as well as an optional `dismissCompletion` closure that will be executed when the route is dismissed. This structure allows
/// the `Router` to efficiently manage routing actions and ensure that any cleanup or additional logic associated with the
/// dismissal of a route is properly handled.
///
/// - Note: `dismissCompletion` currently supports only routes with `presentationStyle` set to `.sheet` and `.fullScreen`.
/// - TODO: The `RouteState` structure is designed to be extended with additional completion handlers, such as `popCompletion`,
///         which will support routes with `presentationStyle` set to navigation-based transitions in future updates.
///
/// - Parameters:
///   - Route: The type of the route, conforming to the `Routable` protocol.
///   - dismissCompletion: An optional closure that will be called when the route is dismissed. This is currently applicable
///                        only to routes with `.sheet` or `.fullScreen` presentation styles.
///   - popCompletion: A future enhancement (currently commented out) that will allow routes to have a completion handler
///                    when they are popped from the navigation stack.
struct RouteState<Route: Routable> {
    /// The route associated with this state.
    ///
    /// This property holds a reference to the route that is currently being managed by the `Router`. It allows the `Router`
    /// to identify which route is being handled and perform the appropriate actions (e.g., routing to, dismissing, or popping
    /// the route).
    let route: Route

    /// A closure that will be executed when the route is dismissed.
    ///
    /// This completion handler is invoked when a route is dismissed using presentation styles such as `.sheet` or `.fullScreen`.
    /// It allows developers to perform additional actions or cleanup when a route is no longer needed.
    ///
    /// - Note: This closure is currently only applicable to `.sheet` and `.fullScreen` presentation styles. Support for
    ///         navigation-based completion handlers, such as `popCompletion`, will be added in future updates.
    let dismissCompletion: (() -> Void)?

    // TODO: -
    // A closure that will be executed when the route is popped from the navigation stack.
    //
    // This completion handler is intended for use with routes that have a `presentationStyle` based on navigation links.
    // It will allow developers to execute custom logic when a route is popped from the stack. This feature is planned for
    // future updates and is currently not implemented.
    //
    let popCompletion: (() -> Void)?
}
