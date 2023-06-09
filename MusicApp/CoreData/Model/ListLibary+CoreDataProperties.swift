//
//  ListLibary+CoreDataProperties.swift
//  
//
//  Created by Nhat on 6/8/23.
//
//

import Foundation
import CoreData


extension ListLibary {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ListLibary> {
        return NSFetchRequest<ListLibary>(entityName: "ListLibary")
    }

    @NSManaged public var libary: NSSet?

}

// MARK: Generated accessors for libary
extension ListLibary {

    @objc(addLibaryObject:)
    @NSManaged public func addToLibary(_ value: Libary)

    @objc(removeLibaryObject:)
    @NSManaged public func removeFromLibary(_ value: Libary)

    @objc(addLibary:)
    @NSManaged public func addToLibary(_ values: NSSet)

    @objc(removeLibary:)
    @NSManaged public func removeFromLibary(_ values: NSSet)

}
