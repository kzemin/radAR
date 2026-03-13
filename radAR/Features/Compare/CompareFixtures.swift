import Foundation

enum CompareFixtures {
    static func products(for category: ProductCategory) -> [FinancialProduct] {
        TransparencyProductDTO.samples(for: category).map(TransparencyProductMapper.map)
    }

    @MainActor
    static func previewStore(
        category: ProductCategory = .termDeposit,
        selectedProductIDs: [String]? = nil
    ) -> CompareStore {
        let suiteName = "radar.compare.preview"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defaults.removePersistentDomain(forName: suiteName)

        let store = CompareStore(
            transparencyService: MockTransparencyService(),
            favoritesStore: FavoritesStore(defaults: defaults)
        )

        let products = self.products(for: category)
        store.selectedCategory = category
        store.favoriteIDs = Set(products.prefix(1).map(\.id))
        store.selectedProductIDs = selectedProductIDs ?? Array(products.prefix(2).map(\.id))
        store.state = .loaded(products)

        return store
    }
}
