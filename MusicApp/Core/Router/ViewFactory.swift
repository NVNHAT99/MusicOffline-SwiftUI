//
//  ViewFactory.swift
//  MusicApp
//
//  Created by Claude
//

import SwiftUI

/// ViewFactory protocol following EasyFax pattern
/// Responsible for creating views based on routes
public protocol ViewFactory: AnyObject {
    associatedtype V: View

    @MainActor
    func view(for route: any Routable, router: any BaseRouterProtocol) -> V
}
