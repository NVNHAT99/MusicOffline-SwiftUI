//
//  PortalRoute.swift
//  MVICore
//
//  Created by Nguyen Thanh Sang (thnhsng) on 19/8/24.
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

/// A protocol that all cross-module routes should conform to.
/// This protocol will be used to identify and map routes across different modules.
public protocol PortalRoute: Sendable, Identifiable, Hashable { }

public extension PortalRoute {
    var id: String { UUID().uuidString }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

/// A protocol that defines the mapping logic for portal routes.
/// Conform to this protocol in the main app to handle routing across modules.
public protocol PortalRouteMappable: Sendable, AnyObject {
    associatedtype Route: Routable

    /// Maps a `PortalRoute` to a specific `Routable` instance.
    /// - Parameter portalRoute: The portal route to map.
    /// - Returns: The corresponding route, if mapping is successful; otherwise, nil.
    @MainActor
    func mapRoute(from portalRoute: any PortalRoute) -> Route?

    @MainActor 
    func portalRoute(for portalRoute: any PortalRoute)
}
