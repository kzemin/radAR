import Foundation

enum FavoriteDomain: String {
    case compareFavorites
    case marketWatchlist
}

actor FavoritesStore {
    private let defaults: UserDefaults
    private let keyPrefix = "radar.favorites"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func favorites(in domain: FavoriteDomain) -> Set<String> {
        let key = storageKey(for: domain)
        let values = defaults.array(forKey: key) as? [String] ?? []
        return Set(values)
    }

    func toggle(_ id: String, in domain: FavoriteDomain) -> Set<String> {
        var current = favorites(in: domain)

        if current.contains(id) {
            current.remove(id)
        } else {
            current.insert(id)
        }

        defaults.set(Array(current).sorted(), forKey: storageKey(for: domain))
        return current
    }

    func count(in domain: FavoriteDomain) -> Int {
        favorites(in: domain).count
    }

    private func storageKey(for domain: FavoriteDomain) -> String {
        "\(keyPrefix).\(domain.rawValue)"
    }
}
