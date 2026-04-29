//
//  SongEntity+CoreDataProperties.swift
//  
//
//  Created by Nhat Nguyen on 8/5/25.
//
//

import Foundation
import CoreData


extension SongEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SongEntity> {
        return NSFetchRequest<SongEntity>(entityName: "SongEntity")
    }

    @NSManaged public var album: String?
    @NSManaged public var artist: String?
    @NSManaged public var dateAdded: Date?
    @NSManaged public var duration: Double
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var url: String?

}
