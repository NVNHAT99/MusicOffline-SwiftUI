//
//  BatchOperations.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/6/25.
//

public struct BatchOperations {
    public var addPaths: [String] = []
    public var updatePaths: [String: String] = [:]
    public var deletePaths: [PathFileElement] = []
    
    public var hasChanges: Bool {
        !addPaths.isEmpty || !updatePaths.isEmpty || !deletePaths.isEmpty
    }
    
    public var hasPendingChanges: Bool {
        !addPaths.isEmpty || !updatePaths.isEmpty
    }
}
