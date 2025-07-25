//
//  ViewExtension.swift
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

/// This is an internal view extension for the MVCore package.
/// Some functions may overlap with the ShareKit package.
/// However, this is necessary to limit dependencies.
extension View {
    /// Conditionally applies a view modifier.
    /// - Parameters:
    ///   - condition: A Boolean value that determines whether to apply the modifier.
    ///   - apply: A view builder that takes the current view and returns a modified view.
    /// - Returns: The modified view if the condition is true; otherwise, the original view.
    @ViewBuilder
    func applyIf<T: View>(_ condition: Bool, @ViewBuilder apply: (Self) -> T) -> some View {
        if condition {
            apply(self)
        } else {
            self
        }
    }

    @ViewBuilder
    func applyIfPresent<U, T: View>(_ optional: U?, @ViewBuilder apply: (U, Self) -> T) -> some View {
        if let unwrapped = optional {
            apply(unwrapped, self)
        } else {
            self
        }
    }

    /// Conditionally applies an asynchronous view modifier.
    /// - Parameters:
    ///   - condition: A Boolean value that determines whether to apply the modifier.
    ///   - apply: An asynchronous view builder that takes the current view and returns a modified view.
    /// - Returns: The modified view if the condition is true; otherwise, the original view.
    @ViewBuilder
    func applyIfAsync<T: View>(
        _ condition: Bool,
        @ViewBuilder apply: @MainActor (Self) async -> T
    ) async -> some View {
        if condition {
            await apply(self)
        } else {
            self
        }
    }

    /// Applies a view modifier.
    /// - Parameter task: A view builder that takes the current view and returns a modified view.
    /// - Returns: The modified view.
    @ViewBuilder
    func task<T: View>(@ViewBuilder task: (Self) -> T) -> some View {
        task(self)
    }

    /// Applies an asynchronous view modifier.
    /// - Parameter task: An asynchronous view builder that takes the current view and returns a modified view.
    /// - Returns: The modified view.
    @ViewBuilder
    func taskAsync<T: View>(
        @ViewBuilder task: @MainActor (Self) async -> T
    ) async -> some View {
        await task(self)
    }
}
