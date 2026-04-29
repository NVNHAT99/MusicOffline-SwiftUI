import Foundation
import CoreData

/// Resolves smart playlist rules to matching songs via NSCompoundPredicate.
final class SmartPlaylistUseCase {

    private let coreData: CoreDataProtocol

    init(coreData: CoreDataProtocol = CoreDataManager.shared) {
        self.coreData = coreData
    }

    func execute(rules: [SmartPlaylistRule]) -> [SongModel] {
        guard !rules.isEmpty else { return [] }
        let predicates = rules.compactMap { Self.predicate(for: $0) }
        guard !predicates.isEmpty else { return [] }

        let compound = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        let request = SongEntity.fetchRequest()
        request.predicate = compound
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]

        let entities = (try? coreData.viewContext.fetch(request)) ?? []
        return entities.map { SongMapper.mapToSongModel(SongEntityMapper.mapToSong($0)) }
    }

    func count(rules: [SmartPlaylistRule]) -> Int {
        guard !rules.isEmpty else { return 0 }
        let predicates = rules.compactMap { Self.predicate(for: $0) }
        guard !predicates.isEmpty else { return 0 }
        let compound = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        let request = SongEntity.fetchRequest()
        request.predicate = compound
        return (try? coreData.viewContext.count(for: request)) ?? 0
    }

    // MARK: - Predicate builder

    static func predicate(for rule: SmartPlaylistRule) -> NSPredicate? {
        let value = rule.value
        switch (rule.field, rule.operator) {
        case (.artist, .equals):
            return NSPredicate(format: "artist ==[cd] %@", value)
        case (.artist, .contains):
            return NSPredicate(format: "artist CONTAINS[cd] %@", value)
        case (.album, .equals):
            return NSPredicate(format: "album ==[cd] %@", value)
        case (.album, .contains):
            return NSPredicate(format: "album CONTAINS[cd] %@", value)
        case (.duration, .greaterThan):
            guard let d = Double(value) else { return nil }
            return NSPredicate(format: "duration > %lf", d)
        case (.duration, .lessThan):
            guard let d = Double(value) else { return nil }
            return NSPredicate(format: "duration < %lf", d)
        case (.dateAdded, .greaterThan):
            guard let date = Self.parseDate(value) else { return nil }
            return NSPredicate(format: "dateAdded > %@", date as CVarArg)
        case (.dateAdded, .lessThan):
            guard let date = Self.parseDate(value) else { return nil }
            return NSPredicate(format: "dateAdded < %@", date as CVarArg)
        default:
            return nil
        }
    }

    private static func parseDate(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)
    }
}
