//
//  PlaylistEntity+CoreDataProperties.swift
//  
//
//  Created by Nhat Nguyen on 7/27/25.
//
//

import Foundation
import CoreData


extension PlaylistEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PlaylistEntity> {
        return NSFetchRequest<PlaylistEntity>(entityName: "PlaylistEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var songs: NSSet?

}

// MARK: Generated accessors for songs
extension PlaylistEntity {

    @objc(addSongsObject:)
    @NSManaged public func addToSongs(_ value: SongEntity)

    @objc(removeSongsObject:)
    @NSManaged public func removeFromSongs(_ value: SongEntity)

    @objc(addSongs:)
    @NSManaged public func addToSongs(_ values: NSSet)

    @objc(removeSongs:)
    @NSManaged public func removeFromSongs(_ values: NSSet)

}
