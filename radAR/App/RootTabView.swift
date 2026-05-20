import SwiftUI

@MainActor
struct RootTabView: View {
    @State private var mapaStore: MapaStore

    init(container: AppContainer) {
        _mapaStore = State(initialValue: container.makeMapaStore())
    }

    var body: some View {
        MapaView(store: mapaStore)
    }
}
