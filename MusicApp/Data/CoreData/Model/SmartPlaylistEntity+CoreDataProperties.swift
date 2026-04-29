import Foundation
import CoreData

extension SmartPlaylistEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SmartPlaylistEntity> {
        return NSFetchRequest<SmartPlaylistEntity>(entityName: "SmartPlaylistEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var rulesJSON: String?
    @NSManaged public var createdAt: Date?
}
