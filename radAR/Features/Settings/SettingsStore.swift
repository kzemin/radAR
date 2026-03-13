import Foundation
import Observation

struct SavedStateSummary {
    var compareFavoritesCount: Int = 0
    var watchlistCount: Int = 0
    var cacheEntries: Int = 0
}

@MainActor
@Observable
final class SettingsStore {
    private let settingsStorage: SettingsStorage
    private let cacheStore: LocalResponseCache
    private let favoritesStore: FavoritesStore

    var settings: AppSettings
    var statusMessage: String?
    let versionDescription: String
    var savedStateSummary = SavedStateSummary()

    init(
        settingsStorage: SettingsStorage,
        cacheStore: LocalResponseCache,
        favoritesStore: FavoritesStore,
        bundle: Bundle = .main
    ) {
        self.settingsStorage = settingsStorage
        self.cacheStore = cacheStore
        self.favoritesStore = favoritesStore
        self.settings = settingsStorage.load()
        self.versionDescription = bundle.radarVersionDescription
    }

    func loadSavedState() async {
        async let compareCountTask = favoritesStore.count(in: .compareFavorites)
        async let watchlistCountTask = favoritesStore.count(in: .marketWatchlist)
        async let cacheCountTask = cacheStore.entryCount()

        savedStateSummary = SavedStateSummary(
            compareFavoritesCount: await compareCountTask,
            watchlistCount: await watchlistCountTask,
            cacheEntries: await cacheCountTask
        )
    }

    func setShowWatchlistFirstOnHome(_ enabled: Bool) {
        settings.showWatchlistFirstOnHome = enabled
        settingsStorage.save(settings)
        statusMessage = enabled
            ? "El Home prioriza tu watchlist local."
            : "El Home vuelve a priorizar el resumen general de mercado."
    }

    func setUseCompactNumbers(_ enabled: Bool) {
        settings.useCompactNumbers = enabled
        settingsStorage.save(settings)
        statusMessage = enabled
            ? "La app va a priorizar números compactos en paneles y listas."
            : "La app va a mostrar números completos cuando corresponda."
    }

    func clearCache() async {
        await cacheStore.clear()
        statusMessage = "Limpiamos la caché local de respuestas públicas."
        await loadSavedState()
    }
}
