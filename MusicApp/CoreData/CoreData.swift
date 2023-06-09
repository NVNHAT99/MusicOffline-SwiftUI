//
//  CoreData.swift
//  MusicApp
//
//  Created by Nhat on 6/8/23.
//

import Foundation
import CoreData

// MARK: - CoreData
class PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentContainer
    
    private init() {
        container = NSPersistentContainer(name: "Libarys")
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError(error.description)
            }
        }
        
    }
    
    var viewContext: NSManagedObjectContext {
        return container.viewContext
    }
    
    func saveContext() {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError(nsError.description)
            }
        }
    }
    
}
