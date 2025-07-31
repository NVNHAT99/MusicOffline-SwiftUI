//
//  ViewPresentation.swift
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

/// A protocol that defines various presentation configurations for views, designed to work seamlessly
/// with the MVI (Model-View-Intent) router in SwiftUI. By conforming to `ViewPresentation`, a view or a route
/// can specify how it should be presented, such as in a sheet, popover, or any other modal form, with options
/// for customizing the presentation style and behavior.
///
/// This protocol includes properties for managing presentation detents, corner radius, interactive dismissal,
/// and compact adaptation strategies, ensuring that the view can be presented consistently across different
/// platforms and size classes.
///
/// - Note: This protocol is available starting from iOS 16.0, macOS 13.0, tvOS 16.0, and watchOS 9.0.
///
/// Properties:
/// - `presentationDetents`: Defines the heights where a sheet naturally rests, allowing for multi-stage
///   presentations, such as half-expanded or fully-expanded states.
/// - `presentationCornerRadius`: Sets the corner radius of the presented view, allowing for a custom
///   appearance or nil to use the system default.
/// - `interactiveDismissDisabled`: Conditionally disables interactive dismissal, preventing the user from
///   swiping down to dismiss the view when it's presented as a sheet or popover.
/// - `presentationCompactAdaptation`: Provides strategies for adapting the presentation to different size classes,
///   ensuring that the presentation behaves appropriately on compact devices like iPhones.
///
/// The protocol also leverages Swift's `Sendable` conformance, ensuring that any types conforming to `ViewPresentation`
/// can be safely used in concurrent environments.
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public protocol ViewPresentation: Sendable {
    /// A set of detents that define where a sheet naturally rests.
    /// This allows a sheet to be partially expanded (e.g., half or three-quarters of the screen) or fully expanded.
    var presentationDetents: Set<PresentationDetent> { get }

    /// The corner radius of the presented view. This property allows for customizing the appearance
    /// of the view's corners when presented, or nil to use the system default.
    var presentationCornerRadius: CGFloat? { get }

    /// A Boolean value that determines whether interactive dismissal is disabled.
    /// When set to true, the user cannot swipe down to dismiss the view. When nil, the system default behavior is used.
    var interactiveDismissDisabled: Bool? { get }

    /// Strategies for adapting a presentation to different size classes, particularly for devices
    /// with compact size classes like the iPhone. This property is available starting from iOS 16.4 and macOS 13.3.
    @available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *)
    var presentationCompactAdaptation: PresentationAdaptation { get }

    var presentationBackground: Color? { get }

    @available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *)
    var presentationBackgroundInteraction: PresentationBackgroundInteraction? { get }

    var presentationDragIndicator: Visibility { get }

    var removePresentationBackgroundInteraction: Bool { get }
}

/// Default implementations for the `ViewPresentation` protocol, providing sensible defaults for optional properties.
///
/// The extension ensures that conforming types only need to implement the properties they want to customize,
/// with default values provided for the rest. This makes it easier to conform to `ViewPresentation` without having
/// to implement every property unless needed.
///
/// Default values:
/// - `presentationDetents`: An empty set, meaning no specific detents are provided.
/// - `presentationCornerRadius`: nil, which allows the system to apply the default corner radius.
/// - `interactiveDismissDisabled`: nil, meaning the system's default interactive dismissal behavior is used.
/// - `presentationCompactAdaptation`: `.automatic`, which allows the system to automatically adapt the presentation
///   for compact size classes starting from iOS 16.4 and macOS 13.3.
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public extension ViewPresentation {
    /// The default value for `presentationDetents` is an empty set, indicating that no specific detents are defined.
    var presentationDetents: Set<PresentationDetent> { [] }

    /// The default value for `presentationCornerRadius` is nil, which means the system default corner radius is used.
    var presentationCornerRadius: CGFloat? { nil }

    /// The default value for `interactiveDismissDisabled` is nil, allowing the system to decide whether
    /// interactive dismissal is enabled based on the context and presentation style.
    var interactiveDismissDisabled: Bool? { nil }

    /// The default strategy for adapting presentations in compact size classes is `.automatic`,
    /// which lets the system determine the best adaptation approach. This property is available
    /// starting from iOS 16.4 and macOS 13.3.
    @available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *)
    var presentationCompactAdaptation: PresentationAdaptation {
        .automatic
    }

    var presentationBackground: Color? { nil }

    @available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *)
    var presentationBackgroundInteraction: PresentationBackgroundInteraction? { nil }

    var presentationDragIndicator: Visibility { .hidden }

    var removePresentationBackgroundInteraction: Bool { false }
}
