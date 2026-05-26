import Foundation

/// Thin wrapper around `UserDefaults` so save/load/delete share one encoder
/// + decoder configuration and one storage key. Not a full Repository<T>
/// abstraction — that would be over-engineering for one key.
protocol UserEQPresetRepositoryProtocol {
    func loadAll() -> [UserEQPreset]
    func save(_ preset: UserEQPreset)
    func delete(id: UUID)
}

final class UserEQPresetRepository: UserEQPresetRepositoryProtocol {

    private static let key = "user_eq_presets_v2"
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadAll() -> [UserEQPreset] {
        guard let data = defaults.data(forKey: Self.key) else { return [] }
        return (try? decoder.decode([UserEQPreset].self, from: data)) ?? []
    }

    func save(_ preset: UserEQPreset) {
        var all = loadAll()
        if let idx = all.firstIndex(where: { $0.id == preset.id }) {
            all[idx] = preset
        } else {
            all.append(preset)
        }
        write(all)
    }

    func delete(id: UUID) {
        let all = loadAll().filter { $0.id != id }
        write(all)
    }

    private func write(_ presets: [UserEQPreset]) {
        guard let data = try? encoder.encode(presets) else { return }
        defaults.set(data, forKey: Self.key)
    }
}
