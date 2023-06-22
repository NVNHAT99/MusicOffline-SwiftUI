//
//  Playlist+CoreDataProperties.swift
//  MusicApp
//
//  Created by Nhat on 6/9/23.
//
//

import Foundation
import CoreData


extension Playlist {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Playlist> {
        return NSFetchRequest<Playlist>(entityName: "Playlist")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var songs: NSObject?
    
    public var wrappedId: String {
        id?.uuidString ?? "Uknow id"
    }
    
    public var wrappedName: String {
        name ?? "Uknow name"
    }
    
    public var songsArray: [String] {
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
    
}

extension Playlist : Identifiable {
    
}
