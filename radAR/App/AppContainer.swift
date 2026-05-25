import Foundation

struct AppContainer {
    let newsService: NewsService

    @MainActor
    static func bootstrap() -> AppContainer {
        AppContainer(newsService: MockNewsService())
    }

    @MainActor
    func makeMapaStore() -> MapaStore {
        MapaStore(newsService: newsService)
    }
}
