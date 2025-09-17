//
//  Routable.swift
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

/// An enumeration representing the different presentation styles available in SwiftUI.
///
/// The `presentationStyle` enum defines how a view can be presented within the application.
/// This enum is used to specify whether a view should be displayed using a navigation link,
/// as a sheet, or in a full-screen mode. Each case corresponds to a different way of presenting
/// views in SwiftUI, allowing for flexible and customizable navigation within the app.
///
/// - Cases:
///   - `navigationLink`: Represents a navigation link presentation style, typically used to push
///     a view onto a navigation stack.
///   - `sheet`: Represents a sheet presentation style, where a view is presented modally, covering
///     part of the screen.
///   - `fullScreen`: Represents a full-screen presentation style, where a view is presented modally,
///     covering the entire screen.
public enum PresentationStyle: Sendable {
    case navigationLink
    case sheet
    case fullScreen
}

/// A typealias that combines `ViewPresentation` and `ZoomTransition` protocols.
///
/// `ViewPresentationCustomize` is a shorthand for types that need to conform to both the `ViewPresentation`
/// and `ZoomTransition` protocols. This typealias simplifies declarations and ensures that types conforming
/// to `ViewPresentationCustomize` can manage both view presentation and zoom transitions seamlessly.
public typealias ViewPresentationCustomize = ViewPresentation & ZoomTransition

/// A typealias that combines `Identifiable`, `Hashable`, and `Sendable` protocols.
///
/// `IdentifiableHashableSendable` is a shorthand for types that need to be identifiable, hashable,
/// and safely sendable across concurrency contexts. This typealias is useful for defining entities
/// that need to be uniquely identified, compared, and safely passed between different threads or tasks.
public typealias IdentifiableHashableSendable = Identifiable & Hashable & Sendable

/// A typealias that combines `IdentifiableHashableSendable` and `ViewPresentationCustomize`.
///
/// `RoutableCustomize` is a shorthand for types that need to conform to `Identifiable`, `Hashable`,
/// `Sendable`, `ViewPresentation`, and `ZoomTransition`. This typealias is typically used for entities
/// that represent a route within the application, providing a unique identity, hashable behavior,
/// safe concurrency handling, and capabilities for view presentation and transitions.
public typealias RoutableCustomize = IdentifiableHashableSendable & ViewPresentationCustomize

/// A protocol defining a routable entity within the application.
///
/// The `Routable` protocol represents an entity that can be navigated to within the app.
/// This protocol combines several key behaviors:
/// - It is `Identifiable`, meaning each route has a unique identity.
/// - It is `Hashable`, allowing routes to be stored in collections like sets or dictionaries.
/// - It is `Sendable`, making routes safe to use in concurrent contexts.
/// - It conforms to `ViewPresentationCustomize`, meaning it can manage both view presentation
///   and zoom transitions.
///
/// The protocol requires a view to be associated with each route, allowing the router to
/// display the correct view based on the route. It also specifies the presentation style
/// to be used when navigating to the route.
///
/// - Associatedtype `V`: The type of view associated with the route.
/// - Properties:
///   - `presentationStyle`: Defines how the route should be presented (e.g., as a navigation link, sheet, or full-screen).
/// - Methods:
///   - `view(attach:)`: Returns the view associated with the route, attaching the appropriate router for navigation.
public protocol Routable: RoutableCustomize {
    associatedtype V: View

    /// The presentation style for routing, determining how the view should be presented.
    var presentationStyle: PresentationStyle { get }

    /// A function that returns the view associated with the route, attaching a router.
    ///
    /// This method provides the view that should be displayed when navigating to this route.
    /// The router is passed as a parameter to allow for further navigation from within the view.
    ///
    /// - Parameter router: The router handling the navigation.
    /// - Returns: The view associated with the route.
    @MainActor
    @ViewBuilder
    func view(attach router: any RouterHandling) -> V
}

/// An extension providing default implementations for the `Routable` protocol.
///
/// This extension offers default behaviors for the `id` property and the `hash(into:)` method,
/// simplifying the implementation of the `Routable` protocol. These defaults are sufficient for
/// most use cases, where the identity of the route is derived from its string representation
/// and the hash value is based on the route's ID.
public extension Routable {
    /// Default implementation for the `id` property, returning a string representation of the route.
    ///
    /// This property provides a unique identifier for the route, typically derived from the route's
    /// string representation. This default implementation assumes that the route's string representation
    /// is unique and sufficient for identifying the route.
    var id: String { "\(Self.self)" }

    /// Default implementation for the `hash(into:)` method, which combines the route's ID into the provided hasher.
    ///
    /// This method allows the route to be used in hash-based collections like sets and dictionaries.
    /// The default implementation uses the route's ID as the basis for its hash value.
    ///
    /// - Parameter hasher: The hasher to use when combining the components of this instance.
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}
