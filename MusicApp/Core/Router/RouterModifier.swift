//
//  RouterModifier.swift
//  MusicApp
//  100% Copied from EasyFax project
//

import SwiftUI

struct RouterModifier<R: BaseRouterProtocol>: ViewModifier {
    @ObservedObject var router: R

    func body(content: Content) -> some View {
        NavigationStack(path: $router.navigationPath) {
            content
                .navigationDestination(for: R.Route.self) { route in
                    router.view(for: route)
                }
        }
        .sheet(item: $router.presentedSheetView) { route in
            router.view(for: route)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(item: $router.presentedFullScreenView) { route in
            router.view(for: route)
        }
    }
}

extension View {
    func withRouting<R: BaseRouterProtocol>(router: R) -> some View {
        modifier(RouterModifier(router: router))
    }
}
