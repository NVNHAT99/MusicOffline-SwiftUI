//
//  ZoomTransition.swift
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

/// A protocol that defines the source identifier (ID) for views involved in zoom transitions.
///
/// `ZoomTransition` is used in SwiftUI to facilitate smooth and coordinated zoom transitions between
/// different views or states. By providing a `sourceID`, this protocol allows views to be linked together
/// for matched geometry effects or other transition effects, enabling a seamless transition between
/// different parts of the UI.
///
/// The protocol leverages Swift's `Sendable` conformance, ensuring that any type conforming to `ZoomTransition`
/// can be safely used in concurrent contexts, which is important for maintaining UI consistency in multi-threaded environments.
///
/// - Properties:
///   - `sourceID`: An optional string identifier that links views together for transitions. This identifier
///     is used by the transition mechanism to match the source and destination views, creating a visual continuity
///     during transitions.
public protocol ZoomTransition: Sendable {
    /// The source identifier (ID) for the zoom transition.
    ///
    /// This ID is used to uniquely identify the view that acts as the source for a zoom transition. When performing
    /// a transition, the system looks for views with matching source IDs to create a smooth visual effect that makes
    /// it appear as though the view is zooming between two different states or locations within the app.
    ///
    /// - Default: The default value for `sourceID` is `nil`, meaning that the view is not participating in a zoom transition
    ///   unless explicitly provided with an ID.
    var sourceID: String? { get }
}

/// Default implementation for the optional `sourceID` property in `ZoomTransition`.
///
/// The extension provides a default value of `nil` for the `sourceID` property, allowing conforming types
/// to omit this property if they do not need to specify a source ID for transitions. This makes the protocol
/// easier to adopt, especially when transitions are not needed or when the source ID can be set dynamically.
public extension ZoomTransition {
    /// The default value for `sourceID` is `nil`.
    ///
    /// By default, the `sourceID` property is `nil`, which means that the view does not participate in a zoom transition
    /// unless an ID is explicitly provided. This allows views to opt-in to transitions only when necessary, avoiding
    /// unnecessary overhead in cases where transitions are not required.
    var sourceID: String? { nil }
}
