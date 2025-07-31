//
//  SongEntity+CoreDataProperties.swift
//  
//
//  Created by Nhat Nguyen on 7/27/25.
//
//

import Foundation
import CoreData


extension SongEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SongEntity> {
        return NSFetchRequest<SongEntity>(entityName: "SongEntity")
    }

    @NSManaged public var id: String?
    @NSManaged public var url: String?
    @NSManaged public var title: String?
    @NSManaged public var artist: String?
    @NSManaged public var duration: Double
    @NSManaged public var album: String?

}
