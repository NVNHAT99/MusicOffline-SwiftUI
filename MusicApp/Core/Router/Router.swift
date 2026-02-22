//
//  Router.swift
//  MusicApp
//  Copied 100% from EasyFax project
//

import SwiftUI
import Combine
import Foundation

@MainActor
public class Router<Route: Routable>: BaseRouterProtocol {
    // MARK: - Published Properties
    @Published public var navigationPath: NavigationPath
    @Published public var presentedView: Route?

    public var presentedSheetView: Route? {
        get { presentedView?.presentationStyle == .sheet ? presentedView : nil }
        set { presentedView = newValue }
    }

    public var presentedFullScreenView: Route? {
        get { presentedView?.presentationStyle == .fullScreen ? presentedView : nil }
        set { presentedView = newValue }
    }

    // MARK: - Parent Router
    public var presentingRouter: BaseRouterProtocol?

    // MARK: - ViewFactory
    private weak var factory: (any ViewFactory)?

    // MARK: - Initialization
    public init(
        path: NavigationPath = .init(),
        presentingRouter: BaseRouterProtocol? = nil,
        factory: (any ViewFactory)? = nil
    ) {
        self.navigationPath = path
        self.presentingRouter = presentingRouter
        self.factory = factory
    }

    // MARK: - Routing
    public func route(to route: Route, dismissCompletion: (() -> Void)? = nil) {
        switch route.presentationStyle {
        case .navigationLink:
            navigationPath.append(route)

        case .sheet:
            presentedView = route

        case .fullScreen:
            presentedView = route
        }
    }

    // MARK: - View Building
    public func view(for route: Route) -> AnyView {
        guard let factory = factory else {
            return AnyView(EmptyView())
        }
        return AnyView(factory.view(for: route, router: self))
    }

    // MARK: - Dismissal
    public func dismiss() {
        // Priority 1: Dismiss current presentation
        if presentedView != nil {
            presentedView = nil
            return
        }

        // Priority 2: Ask parent router to dismiss
        if let parent = presentingRouter {
            parent.dismissAll()
            return
        }

        // Priority 3: Root router - nothing to dismiss
    }

    public func dismissAll() {
        if let parent = presentingRouter {
            parent.dismissAll()
        } else {
            presentedView = nil
        }
    }

    public func popToRoot() {
        navigationPath.removeLast(navigationPath.count)
    }
}
