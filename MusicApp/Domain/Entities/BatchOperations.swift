//
//  BatchOperations.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/6/25.
//

import Foundation

struct BatchOperations {
    var addPaths: [String] = []
    var updatePaths: [String: String] = [:]
    var deletePaths: [PathFileElement] = []
    
    var hasChanges: Bool {
        !addPaths.isEmpty || !updatePaths.isEmpty || !deletePaths.isEmpty
    }
    
    var hasPendingChanges: Bool {
        !addPaths.isEmpty || !updatePaths.isEmpty
    }
}
