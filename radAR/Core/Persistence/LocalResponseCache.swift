import Foundation

actor LocalResponseCache {
    private struct Entry: Codable {
        let payload: Data
        let expirationDate: Date
    }

    private let defaults: UserDefaults
    private let keyPrefix = "radar.cache"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func data(for key: String) -> Data? {
        let storageKey = storageKey(for: key)
        guard let rawData = defaults.data(forKey: storageKey),
              let entry = try? JSONDecoder().decode(Entry.self, from: rawData) else {
            return nil
        }

        guard entry.expirationDate > .now else {
            defaults.removeObject(forKey: storageKey)
            return nil
        }

        return entry.payload
    }

    func insert(_ data: Data, for key: String, ttl: TimeInterval) {
        let entry = Entry(
            payload: data,
            expirationDate: .now.addingTimeInterval(ttl)
        )

        guard let rawData = try? JSONEncoder().encode(entry) else {
            return
        }

        defaults.set(rawData, forKey: storageKey(for: key))
    }

    func clear() {
        defaults.dictionaryRepresentation().keys
            .filter { $0.hasPrefix(keyPrefix) }
            .forEach(defaults.removeObject(forKey:))
    }

    func entryCount() -> Int {
        defaults.dictionaryRepresentation().keys
            .filter { $0.hasPrefix(keyPrefix) }
            .count
    }

    private func storageKey(for key: String) -> String {
        "\(keyPrefix).\(key)"
    }
}
