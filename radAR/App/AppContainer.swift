import Foundation

struct AppContainer {
    let newsService: NewsService
    let marketService: MarketService

    @MainActor
    static func bootstrap() -> AppContainer {
        AppContainer(
            newsService: SupabaseNewsService(),
            marketService: DolarApiMarketService()
        )
    }

    @MainActor
    func makeMapaStore() -> MapaStore {
        MapaStore(newsService: newsService, marketService: marketService)
    }
}
