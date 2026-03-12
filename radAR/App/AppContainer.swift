import Foundation

struct AppContainer {
    let apiClient: any APIClient
    let cacheStore: LocalResponseCache
    let favoritesStore: FavoritesStore
    let settingsStorage: SettingsStorage
    let transparencyService: any TransparencyServicing
    let marketService: any MarketServicing
    let settingsStore: SettingsStore

    @MainActor
    static func bootstrap() -> AppContainer {
        let cacheStore = LocalResponseCache()
        let favoritesStore = FavoritesStore()
        let settingsStorage = SettingsStorage()
        let apiClient = URLSessionAPIClient(
            baseURL: URL(string: "https://api.bcra.gob.ar")!,
            session: .shared,
            cacheStore: cacheStore
        )
        let settingsStore = SettingsStore(
            settingsStorage: settingsStorage,
            cacheStore: cacheStore,
            favoritesStore: favoritesStore
        )

        return AppContainer(
            apiClient: apiClient,
            cacheStore: cacheStore,
            favoritesStore: favoritesStore,
            settingsStorage: settingsStorage,
            transparencyService: BCRATransparencyService(apiClient: apiClient),
            marketService: BCRAMarketService(apiClient: apiClient),
            settingsStore: settingsStore
        )
    }

    @MainActor
    func makeProductRadarStore() -> HomeStore {
        HomeStore(
            transparencyService: transparencyService,
            marketService: marketService,
            favoritesStore: favoritesStore,
            settingsStorage: settingsStorage
        )
    }

    @MainActor
    func makeCompareStore() -> CompareStore {
        CompareStore(
            transparencyService: transparencyService,
            favoritesStore: favoritesStore
        )
    }

    @MainActor
    func makeHomeMonitorStore() -> MarketStore {
        MarketStore(
            marketService: marketService,
            favoritesStore: favoritesStore
        )
    }
}
