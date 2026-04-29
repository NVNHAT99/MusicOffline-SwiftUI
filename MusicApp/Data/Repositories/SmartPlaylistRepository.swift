import Foundation
import CoreData

final class SmartPlaylistRepository: SmartPlaylistRepositoryProtocol {

    private let coreData: CoreDataProtocol

    init(coreData: CoreDataProtocol = CoreDataManager.shared) {
        self.coreData = coreData
    }

    func fetchAll() throws -> [SmartPlaylist] {
        let context = coreData.viewContext
        let request = SmartPlaylistEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        let entities = try context.fetch(request)
        return entities.compactMap { Self.map($0) }
    }

    func save(_ playlist: SmartPlaylist) throws {
        let context = coreData.viewContext
        // Find existing or create new
        let request = SmartPlaylistEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", playlist.id as CVarArg)
        let existing = try context.fetch(request).first
        let entity = existing ?? SmartPlaylistEntity(context: context)
        entity.id = playlist.id
        entity.name = playlist.name
        entity.createdAt = playlist.createdAt
        entity.rulesJSON = Self.encodeRules(playlist.rules)
        try context.save()
    }

    func delete(id: UUID) throws {
        let context = coreData.viewContext
        let request = SmartPlaylistEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        if let entity = try context.fetch(request).first {
            context.delete(entity)
            try context.save()
        }
    }

    // MARK: - Helpers

    private static func map(_ entity: SmartPlaylistEntity) -> SmartPlaylist? {
        guard let id = entity.id, let name = entity.name else { return nil }
        let rules = decodeRules(entity.rulesJSON)
        return SmartPlaylist(id: id, name: name, rules: rules, createdAt: entity.createdAt ?? Date())
    }

    private static func encodeRules(_ rules: [SmartPlaylistRule]) -> String {
        let data = try? JSONEncoder().encode(rules)
        return data.flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
    }

    private static func decodeRules(_ json: String?) -> [SmartPlaylistRule] {
        guard let json, let data = json.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([SmartPlaylistRule].self, from: data)) ?? []
    }
}
