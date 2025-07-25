//
//  SampleRouter.swift
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

public enum TestRoute: Routable {
    case viewA
    case viewB
    case viewC
    case viewD
    case viewE
    case viewF
    case viewG // for view presentation
    case viewH // for zoom transition
    case viewI // for zoom transition

    case viewJ

    public var presentationStyle: PresentationStyle {
        switch self {
        case .viewA: .sheet
        case .viewB: .navigationLink
        case .viewC: .navigationLink
        case .viewD: .navigationLink
        case .viewE: .sheet
        case .viewF: .fullScreen
        case .viewG: .sheet
        case .viewH: .sheet
        case .viewI: .navigationLink
        case .viewJ: .sheet
        }
    }

    public var sourceID: String? {
        switch self {
        case .viewH: "viewH"
        case .viewI: "viewI"
        default: nil
        }
    }

    public var presentationDetents: Set<PresentationDetent> {
        switch self {
        case .viewG: [.medium, .large, .fraction(0.75)]
        case .viewJ: [.height(330)]
        default: []
        }
    }

    public var presentationCornerRadius: CGFloat? {
        switch self {
        case .viewG: 25.0
        default: nil
        }
    }

    public var presentationBackground: Color? {
        switch self {
        case .viewJ: .clear
        default: nil
        }
    }

    @ViewBuilder
    public func view(attach router: any RouterHandling) -> some View {
        switch self {
        case .viewA: ViewABuilder(router: router).build()
        case .viewB: ViewBBuilder(router: router).build()
        case .viewC: ViewCBuilder(router: router).build()
        case .viewD: ViewDBuilder(router: router).build()
        case .viewE: ViewEBuilder(router: router).build()
        case .viewF: ViewFBuilder(router: router).build()
        case .viewG: ViewG()
        case .viewH: ViewH()
        case .viewI: ViewI()
        case .viewJ:
            if #available(iOS 16.4, macOS 13.3, *) {
                Text("View J")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 10)
                    .padding()
                    .presentationBackground(
                        self.presentationBackground ?? .black
                    )
            } else {
                EmptyView()
            }
        }
    }
}

// MARK: - View A - Router

struct ViewA: View {
    @ObservedObject var container: ViewAContainer<TestRoute>

    init(container: ViewAContainer<TestRoute>) {
        _container = .init(wrappedValue: container)
    }

    var body: some View {
        VStack(spacing: 20) {
            Button("**PUSH** to View **C**") {
                container.route(to: .viewC)
            }

            Button("**POP** View") {
                container.router.pop()
            }

            Button("**Dismiss**") {
                container.router.dismiss()
            }
        }
        .navigationTitle("View A")
        .embedded(
            navigation: .splitView,
            with: container.router
        )
    }
}

final class ViewAContainer<Route: Routable>: ObservableObject {

    let router: Router<Route>

    init(handler: Router<Route>) {
        self.router = handler
    }

    @MainActor
    func route(to route: Route, dismissCompletion: (() -> Void)? = nil) {
        router.route(to: route, dismissCompletion: dismissCompletion)
    }
}

struct ViewABuilder {
    let router: Router<TestRoute>

    @MainActor
    init(router: any RouterHandling) {
        guard let router = router as? Router<TestRoute> else {
            self.router = .init()
            return
        }
        self.router = router
    }

    @MainActor
    func build() -> some View {
        let container = ViewAContainer(handler: router)
        return ViewA(container: container)
    }
}

// MARK: - View B - Router

struct ViewB: View {
    @ObservedObject var router: Router<TestRoute>

    init(router: Router<TestRoute>) {
        self._router = .init(wrappedValue: router)
    }

    var body: some View {
        Text("View B")
            .font(.largeTitle)
    }
}

struct ViewBBuilder {
    let router: Router<TestRoute>

    @MainActor
    init(router: any RouterHandling) {
        guard let router = router as? Router<TestRoute> else {
            self.router = .init()
            return
        }
        self.router = router
    }

    @MainActor
    func build() -> some View {
        ViewB(router: router)
    }
}

// MARK: - View C - Router

struct ViewC: View {
    @ObservedObject var router: Router<TestRoute>

    init(router: Router<TestRoute>) {
        self._router = .init(wrappedValue: router)
    }

    var body: some View {
        VStack(spacing: 20) {
            Button("**PUSH** to View **D**") {
                router.route(to: .viewD)
            }

            Button("**POP TO ROOT**") {
                router.popToRoot()
            }

            Button("**POP** View") {
                router.pop()
            }

            Button("Dismiss") {
                router.dismiss()
            }
        }
        .navigationTitle("View C")
    }
}

struct ViewCBuilder {
    let router: Router<TestRoute>

    @MainActor
    init(router: any RouterHandling) {
        guard let router = router as? Router<TestRoute> else {
            self.router = .init()
            return
        }
        self.router = router
    }

    @MainActor
    func build() -> some View {
        ViewC(router: router)
    }
}

// MARK: - View D - Router

struct ViewD: View {
    @ObservedObject var router: Router<TestRoute>

    init(router: Router<TestRoute>) {
        self._router = .init(wrappedValue: router)
    }

    var body: some View {
        VStack(spacing: 20) {
            Button("**SHEET** to view E") {
                router.route(to: .viewE)
            }

            Button("**POP TO ROOT**") {
                router.popToRoot()
            }

            Button("**POP** View") {
                router.pop()
            }

            Button("Dismiss") {
                router.dismiss()
            }
        }
        .navigationTitle("View D")
    }
}

struct ViewDBuilder {
    let router: Router<TestRoute>

    @MainActor
    init(router: any RouterHandling) {
        guard let router = router as? Router<TestRoute> else {
            self.router = .init()
            return
        }
        self.router = router
    }

    @MainActor
    func build() -> some View {
        ViewD(router: router)
    }
}

// MARK: - View E - Router

struct ViewE: View {
    @ObservedObject var router: Router<TestRoute>

    init(router: Router<TestRoute>) {
        self._router = .init(wrappedValue: router)
    }

    var body: some View {
        VStack(spacing: 20) {
            Button("**POP TO ROOT**") {
                router.popToRoot()
            }

            Button("**POP** View") {
                router.pop()
            }

            Button("Dismiss") {
                router.dismiss()
            }

            Button("Dismiss **ALL**") {
                router.dismissAll()
            }

            Button("sheet to **viewG**") {
                router.route(to: .viewG)
            }
        }
        .navigationTitle("View E")
        .embedded(
            navigation: .splitView,
            with: router
        )
    }
}

struct ViewEBuilder {
    let router: Router<TestRoute>

    @MainActor
    init(router: any RouterHandling) {
        guard let router = router as? Router<TestRoute> else {
            self.router = .init()
            return
        }
        self.router = router
    }

    @MainActor
    func build() -> some View {
        ViewE(router: router)
    }
}

// MARK: - View F - Router

struct ViewF: View {
    @ObservedObject var router: Router<TestRoute>

    init(router: Router<TestRoute>) {
        self._router = .init(wrappedValue: router)
    }

    var body: some View {
        VStack(spacing: 20) {
            Button("**POP TO ROOT**") {
                router.popToRoot()
            }

            Button("**POP** View") {
                router.pop()
            }

            Button("Dismiss") {
                router.dismiss()
            }
        }
        .navigationTitle("View F")
        .embedded(
            navigation: .splitView,
            with: router
        )
    }
}

struct ViewFBuilder {
    let router: Router<TestRoute>

    @MainActor
    init(router: any RouterHandling) {
        guard let router = router as? Router<TestRoute> else {
            self.router = .init()
            return
        }
        self.router = router
    }

    @MainActor
    func build() -> some View {
        ViewF(router: router)
    }
}

// MARK: - View G - View presentation

struct ViewG: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("View G - View presentation")
                .font(.title)
                .fontWeight(.bold)
                .padding()

            if #available(iOS 18.0, macOS 15.0, *) {
                Image(systemName: "chevron.up.2")
                    .foregroundColor(.purple)
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .symbolEffect(.wiggle)
            } else {
                Image(systemName: "chevron.up.2")
            }
        }
    }
}

// MARK: - View H - Zoom Transition

struct ViewH: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("View H - Zoom Transition")
                .font(.title)
                .fontWeight(.bold)
                .padding()

            Text("Swipe down to dissmiss")

            if #available(iOS 18.0, macOS 15.0, *) {
                Image(systemName: "chevron.down.2")
                    .foregroundColor(.green)
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .symbolEffect(.wiggle)
            } else {
                Image(systemName: "chevron.down.2")
            }
        }
    }
}

// MARK: - View I - Zoom Transition

struct ViewI: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("View I - Zoom Transition")
                .font(.title)
                .fontWeight(.bold)
                .padding()

            Text("Swipe right to pop")

            if #available(iOS 18.0, macOS 15.0, *) {
                Image(systemName: "chevron.right.2")
                    .foregroundColor(.orange)
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .symbolEffect(.wiggle)
            } else {
                Image(systemName: "chevron.right.2")
            }
        }
    }
}

// MARK: - Main contentView

public struct FullSampleRouter: View {
    @ObservedObject var router: Router<TestRoute> = Router()
    // Required for zoom transition
    @Namespace var namespace

    public init() { }

    public var body: some View {
        VStack(spacing: 20) {
            Button("**FULLSCREEN** to View **F**") {
                router.route(to: .viewF) {
                    debugPrint("Dismiss **ViewF**")
                }
            }

            Button("**SHEET** to View **A**") {
                router.route(to: .viewA) {
                    debugPrint("Dismiss **ViewA**")
                }
            }

            Button("**PUSH** to View **B**") {
                router.route(to: .viewB) {
                    debugPrint("POP completion: **ViewB**")
                }
            }

            Button("**SHEET** to View **G** with custom **presentation**") {
                router.route(to: .viewG)
            }
            .padding()
            .foregroundStyle(.white)
            .background(Color.purple)
            .clipShape(RoundedRectangle(cornerRadius: 25))

            Button("**Transition** to View **H** with **ZOOM**") {
                router.route(to: .viewH)
            }
            .padding()
            .foregroundStyle(.white)
            .background(Color.green)
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .matchedTransitionSource(
                source: TestRoute.viewH,
                namespace: namespace
            )

            Button("**Transition** to View **I**  with **ZOOM**") {
                router.route(to: .viewI)
            }
            .padding()
            .foregroundStyle(.white)
            .background(Color.orange)
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .buttonStyle(.plain)
            .matchedTransitionSource(
                source: TestRoute.viewI,
                namespace: namespace
            )
        }
        .navigationTitle("Sample Router")
        .embedded(
            navigation: .splitView,
            with: router,
            namespace: namespace
        )
    }
}

#Preview {
    FullSampleRouter()
}
