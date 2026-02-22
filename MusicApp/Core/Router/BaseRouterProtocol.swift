//
//  BaseRouterProtocol.swift
//  MusicApp
//  Copied from EasyFax project
//

import SwiftUI
import Foundation

@MainActor
public protocol BaseRouterProtocol: ObservableObject {
    associatedtype Route: Routable

    var navigationPath: NavigationPath { get set }
    var presentedView: Route? { get set }
    var presentedSheetView: Route? { get set }
    var presentedFullScreenView: Route? { get set }

    var presentingRouter: BaseRouterProtocol? { get set }

    func route(to route: Route, dismissCompletion: (() -> Void)?)
    func dismiss()
    func dismissAll()
    func popToRoot()

    @ViewBuilder func view(for route: Route) -> AnyView
}

// MARK: - Type Erasure
public typealias AnyRouter = BaseRouterProtocol
