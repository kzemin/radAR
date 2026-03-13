import Foundation

enum MarketFixturesPreview {
    @MainActor
    static func previewStore() -> MarketStore {
        let suiteName = "radar.market.preview"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defaults.removePersistentDomain(forName: suiteName)

        let store = MarketStore(
            marketService: MockMarketService(),
            favoritesStore: FavoritesStore(defaults: defaults)
        )

        let seriesByQuote = Dictionary(
            uniqueKeysWithValues: MarketFixtures.overview.quotes.map { quote in
                (quote.id, MarketFixtures.series(for: quote.id))
            }
        )

        store.state = .loaded(
            MarketMapper.map(
                overview: MarketFixtures.overview,
                seriesByQuote: seriesByQuote
            )
        )
        store.watchlistIDs = ["usd_mep", "usd_oficial", "badlar"]
        store.selectedQuoteID = "usd_mep"
        store.selectedRange = .thirtyDays
        return store
    }
}
