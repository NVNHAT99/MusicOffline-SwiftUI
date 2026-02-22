//
//  Routable.swift
//  MusicApp
//
//  Refactored to match EasyFax pattern
//

import Foundation

// MARK: - Presentation Style
public enum PresentationStyle: Sendable {
    case navigationLink  // Push navigation
    case sheet           // Sheet presentation
    case fullScreen      // Full screen cover
}

// MARK: - RoutableCustomize Protocol
public protocol RoutableCustomize {
    var presentationStyle: PresentationStyle { get }
}

// MARK: - Routable Protocol
public protocol Routable: RoutableCustomize, Identifiable, Hashable {
}

// MARK: - Default Implementation
extension Routable {
    public var presentationStyle: PresentationStyle {
        return .navigationLink
    }

    public var id: String {
        return String(describing: self)
    }
}
