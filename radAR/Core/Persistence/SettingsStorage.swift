import Foundation

final class SettingsStorage {
    private enum Keys {
        static let showWatchlistFirstOnHome = "radar.settings.showWatchlistFirstOnHome"
        static let useCompactNumbers = "radar.settings.useCompactNumbers"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> AppSettings {
        AppSettings(
            showWatchlistFirstOnHome: defaults.object(forKey: Keys.showWatchlistFirstOnHome) as? Bool ?? true,
            useCompactNumbers: defaults.object(forKey: Keys.useCompactNumbers) as? Bool ?? true
        )
    }

    func save(_ settings: AppSettings) {
        defaults.set(settings.showWatchlistFirstOnHome, forKey: Keys.showWatchlistFirstOnHome)
        defaults.set(settings.useCompactNumbers, forKey: Keys.useCompactNumbers)
    }
}
