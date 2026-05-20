import Foundation

struct AppContainer {
    @MainActor
    static func bootstrap() -> AppContainer {
        AppContainer()
    }

    @MainActor
    func makeMapaStore() -> MapaStore {
        MapaStore()
    }
}
