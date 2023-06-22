//
//  ListPlayList+CoreDataProperties.swift
//  MusicApp
//
//  Created by Nhat on 6/9/23.
//
//

import Foundation
import CoreData


extension ListPlayList {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ListPlayList> {
        return NSFetchRequest<ListPlayList>(entityName: "ListPlayList")
    }

    @NSManaged public var libarys: NSSet?
    
}

// MARK: Generated accessors for libary
extension ListPlayList {

    @objc(addLibaryObject:)
    @NSManaged public func addToLibary(_ value: Playlist)

    @objc(removeLibaryObject:)
    @NSManaged public func removeFromLibary(_ value: Playlist)

    @objc(addLibary:)
    @NSManaged public func addToLibary(_ values: NSSet)

    @objc(removeLibary:)
    @NSManaged public func removeFromLibary(_ values: NSSet)

}

extension ListPlayList : Identifiable {

}
