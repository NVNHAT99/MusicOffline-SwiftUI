//
//  Libary+CoreDataProperties.swift
//  
//
//  Created by Nhat on 6/8/23.
//
//

import Foundation
import CoreData


extension Libary {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Libary> {
        return NSFetchRequest<Libary>(entityName: "Libary")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var songs: NSObject?
    @NSManaged public var name: String?
    @NSManaged public var list: ListLibary?
    
    public var wrappedId: String {
        id?.uuidString ?? "unkown id"
    }
    
    public var wrappedSongsArray: [String] {
        get {
            guard let data = songs as? Data else { return [] }
            do {
                let decoder = JSONDecoder()
                return try decoder.decode([String].self, from: data)
            } catch {
                print("Error decoding songs: \(error)")
                return []
            }
        }
        set {
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(newValue)
                songs = data as NSObject
            } catch {
                print("Error encoding songs: \(error)")
            }
        }
    }
    
    public var wrappedName: String {
        name ?? "Uknow name"
    }
    
     
    public var wrappedList: ListLibary? {
        return list
    }
}
