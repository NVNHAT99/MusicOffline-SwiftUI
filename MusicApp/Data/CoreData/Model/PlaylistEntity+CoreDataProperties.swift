//
//  PlaylistEntity+CoreDataProperties.swift
//  
//
//  Created by Nhat Nguyen on 8/10/25.
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
    @NSManaged public var songIDs: NSArray?

}

extension PlaylistEntity {
    var songIDStrings: [String] {
        get { songIDs as? [String] ?? [] }
        set { songIDs = newValue as NSArray }
    }
    
    var songUUIDs: [UUID] {
        get { songIDStrings.compactMap { UUID(uuidString: $0) } }
        set { songIDStrings = newValue.map { $0.uuidString } }
    }
}
