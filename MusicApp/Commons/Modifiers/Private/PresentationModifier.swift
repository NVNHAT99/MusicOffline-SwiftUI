//
//  PresentationModifier.swift
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

/// A view modifier that applies various presentation styles to a view, allowing customization of the view's appearance
/// and behavior when it is presented as a modal or in other contexts. This modifier is designed to be flexible,
/// adapting to different presentation configurations provided by a `ViewPresentation` type.
///
/// The modifier supports features such as presentation detents, corner radius, and interactive dismiss behavior.
/// It conditionally applies these features based on the configuration, ensuring compatibility with different versions
/// of iOS, macOS, tvOS, and watchOS.
///
/// - Note: This modifier requires iOS 16.0, macOS 13.0, tvOS 16.0, or watchOS 9.0, or later.
///
/// - Parameters:
///   - Presentation: A type conforming to `ViewPresentation`, which defines the presentation styles to be applied.
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
struct PresentationModifier<Presentation: ViewPresentation>: ViewModifier {

    /// The presentation configuration that determines how the view should be presented.
    /// This includes properties such as detents, corner radius, and whether interactive dismissal is allowed.
    let presentation: Presentation

    /// Applies the presentation styles to the content view based on the provided configuration.
    /// This method uses conditional modifiers to apply styles only when they are specified in the presentation configuration.
    ///
    /// - Parameter content: The content view to which the presentation styles are applied.
    /// - Returns: A view modified with the presentation properties, such as detents, corner radius, and dismiss behavior.
    func body(content: Content) -> some View {
        content
        /// Applies presentation detents to the view if they are specified in the configuration.
        /// Detents control how much of the screen the presented view should cover.
            .applyIf(!presentation.presentationDetents.isEmpty) {
                $0.presentationDetents(presentation.presentationDetents)
            }
        /// Applies a corner radius to the presented view if specified in the configuration.
        /// The corner radius is only applied if the platform version supports it.
            .applyIf(presentation.presentationCornerRadius != nil) {
                if #available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *) {
                    $0.presentationCornerRadius(presentation.presentationCornerRadius)
                } else { $0 }
            }
        /// Disables interactive dismissal of the presented view if specified in the configuration.
        /// This prevents the user from swiping down to dismiss the view unless allowed.
            .applyIf(presentation.interactiveDismissDisabled != nil) {
                $0.interactiveDismissDisabled(presentation.interactiveDismissDisabled ?? false)
            }
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension View {
    /// Applies the `PresentationModifier` to the view, using the specified route that conforms to both `Routable` and `ViewPresentation` protocols.
    /// This extension simplifies the process of applying presentation styles based on a route's configuration.
    ///
    /// - Parameter route: A type conforming to both `Routable` and `ViewPresentation`, which provides the necessary presentation configuration.
    /// - Returns: A view modified with the presentation properties defined by the route.
    func applyViewPresentation<Route: Routable & ViewPresentation>(route: Route) -> some View {
        self.modifier(PresentationModifier(presentation: route))
    }
}
