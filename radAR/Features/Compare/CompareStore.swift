import Foundation
import Observation

struct CompareTableColumn: Hashable, Identifiable {
    let kind: CompareTableColumnKind
    let shortTitle: String
    let longTitle: String

    var id: CompareTableColumnKind { kind }
}

enum CompareTableColumnKind: Hashable {
    case compare
    case entity
    case product
    case monthlyFee
    case rate
    case annualCost
    case minimumRequirement
    case updated
    case favorite

    var isMetric: Bool {
        switch self {
        case .monthlyFee, .rate, .annualCost, .minimumRequirement:
            return true
        case .compare, .entity, .product, .updated, .favorite:
            return false
        }
    }

    var prefersHigher: Bool {
        switch self {
        case .rate:
            return true
        case .monthlyFee, .annualCost, .minimumRequirement, .compare, .entity, .product, .updated, .favorite:
            return false
        }
    }
}

@MainActor
@Observable
final class CompareStore {
    private let transparencyService: any TransparencyServicing
    private let favoritesStore: FavoritesStore

    private let comparisonLimit = 3

    var state: LoadableState<[FinancialProduct]> = .idle
    var selectedCategory: ProductCategory = .savingsAccount
    var searchQuery = ""
    var sortOption: ProductSortOption = .name
    var showFavoritesOnly = false
    var favoriteIDs: Set<String> = []
    var selectedProductIDs: [String] = []

    init(
        transparencyService: any TransparencyServicing,
        favoritesStore: FavoritesStore
    ) {
        self.transparencyService = transparencyService
        self.favoritesStore = favoritesStore
    }

    var filteredProducts: [FinancialProduct] {
        let products = state.value ?? []
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)

        let searched = products.filter { product in
            guard !query.isEmpty else {
                return true
            }

            return product.name.localizedCaseInsensitiveContains(query)
                || product.institution.localizedCaseInsensitiveContains(query)
                || product.summary.localizedCaseInsensitiveContains(query)
                || product.highlights.joined(separator: " ").localizedCaseInsensitiveContains(query)
        }

        let favoriteFiltered = showFavoritesOnly
            ? searched.filter { favoriteIDs.contains($0.id) }
            : searched

        switch sortOption {
        case .name:
            return favoriteFiltered.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        case .institution:
            return favoriteFiltered.sorted {
                $0.institution.localizedCaseInsensitiveCompare($1.institution) == .orderedAscending
            }
        case .monthlyFee:
            return favoriteFiltered.sorted {
                ($0.monthlyFee ?? Double.greatestFiniteMagnitude) < ($1.monthlyFee ?? Double.greatestFiniteMagnitude)
            }
        case .rate:
            return favoriteFiltered.sorted {
                ($0.rate ?? -Double.greatestFiniteMagnitude) > ($1.rate ?? -Double.greatestFiniteMagnitude)
            }
        case .annualCost:
            return favoriteFiltered.sorted {
                ($0.annualCost ?? Double.greatestFiniteMagnitude) < ($1.annualCost ?? Double.greatestFiniteMagnitude)
            }
        case .updated:
            return favoriteFiltered.sorted { $0.updatedAt > $1.updatedAt }
        }
    }

    var tableColumns: [CompareTableColumn] {
        [
            .init(kind: .compare, shortTitle: "Cmp", longTitle: "Comparar"),
            .init(kind: .entity, shortTitle: "Entidad", longTitle: "Entidad"),
            .init(kind: .product, shortTitle: "Producto", longTitle: "Producto"),
            .init(kind: .monthlyFee, shortTitle: "Comis.", longTitle: "Comisión"),
            .init(kind: .rate, shortTitle: "Tasa", longTitle: "Tasa nominal anual"),
            .init(kind: .annualCost, shortTitle: "Costo", longTitle: "Costo relevante"),
            .init(kind: .minimumRequirement, shortTitle: "Req.", longTitle: "Requisito mínimo"),
            .init(kind: .updated, shortTitle: "Upd.", longTitle: "Actualizado"),
            .init(kind: .favorite, shortTitle: "Fav", longTitle: "Favorito")
        ]
    }

    var selectedProducts: [FinancialProduct] {
        let productsByID = Dictionary(uniqueKeysWithValues: (state.value ?? []).map { ($0.id, $0) })
        return selectedProductIDs.compactMap { productsByID[$0] }
    }

    var comparisonSnapshot: ProductComparisonSnapshot? {
        guard selectedProducts.count >= 2 else {
            return nil
        }

        return ProductComparisonSnapshot(
            products: selectedProducts,
            rows: comparisonRows(for: selectedProducts)
        )
    }

    var selectionSummary: String {
        "\(selectedProductIDs.count)/\(comparisonLimit) seleccionados"
    }

    var selectionDetails: String {
        if selectedProductIDs.isEmpty {
            return "Sin selección"
        }

        let names = selectedProducts.map(\.institution)
        return names.joined(separator: " · ")
    }

    func loadIfNeeded() async {
        guard case .idle = state else {
            return
        }

        await refresh()
    }

    func refresh() async {
        state = .loading

        do {
            async let productsTask = transparencyService.fetchProducts(for: selectedCategory)
            async let favoritesTask = favoritesStore.favorites(in: .compareFavorites)

            let products = try await productsTask
            favoriteIDs = await favoritesTask
            let validIDs = Set(products.map(\.id))
            selectedProductIDs = selectedProductIDs.filter { validIDs.contains($0) }

            state = products.isEmpty
                ? .empty("No encontramos productos para la categoría seleccionada.")
                : .loaded(products)
        } catch let error as AppError {
            state = .failed(error)
        } catch {
            state = .failed(.service("No pudimos cargar la comparación de productos."))
        }
    }

    func toggleFavorite(_ product: FinancialProduct) {
        Task { @MainActor in
            favoriteIDs = await favoritesStore.toggle(product.id, in: .compareFavorites)
        }
    }

    func toggleSelection(_ product: FinancialProduct) {
        if let index = selectedProductIDs.firstIndex(of: product.id) {
            selectedProductIDs.remove(at: index)
            return
        }

        guard selectedProductIDs.count < comparisonLimit else {
            return
        }

        selectedProductIDs.append(product.id)
    }

    func clearSelection() {
        selectedProductIDs.removeAll()
    }

    func isFavorite(_ product: FinancialProduct) -> Bool {
        favoriteIDs.contains(product.id)
    }

    func isSelected(_ product: FinancialProduct) -> Bool {
        selectedProductIDs.contains(product.id)
    }

    func canSelect(_ product: FinancialProduct) -> Bool {
        isSelected(product) || selectedProductIDs.count < comparisonLimit
    }

    func metricValue(for product: FinancialProduct, kind: CompareTableColumnKind) -> FinancialMetric? {
        switch kind {
        case .monthlyFee:
            return FinancialMetric(value: product.monthlyFee, format: .currency(code: product.currencyCode))
        case .rate:
            return FinancialMetric(value: product.rate, format: .percentage)
        case .annualCost:
            return FinancialMetric(value: product.annualCost, format: .percentage)
        case .minimumRequirement:
            return FinancialMetric(value: product.minimumIncome, format: .currency(code: product.currencyCode))
        case .compare, .entity, .product, .updated, .favorite:
            return nil
        }
    }

    func displayValue(for product: FinancialProduct, column: CompareTableColumn) -> String {
        switch column.kind {
        case .compare:
            return isSelected(product) ? "ON" : "OFF"
        case .entity:
            return product.institution
        case .product:
            return product.name
        case .updated:
            return RadarFormatters.shortDate(product.updatedAt)
        case .favorite:
            return isFavorite(product) ? "STAR" : "-"
        case .monthlyFee, .rate, .annualCost, .minimumRequirement:
            guard let metric = metricValue(for: product, kind: column.kind) else {
                return "—"
            }

            return RadarFormatters.metric(metric, compact: true)
        }
    }

    func updatedInfo(for product: FinancialProduct) -> String {
        RadarFormatters.shortTime(product.updatedAt)
    }

    func isBest(_ product: FinancialProduct, for kind: CompareTableColumnKind) -> Bool {
        guard kind.isMetric, let currentValue = numericValue(for: product, kind: kind) else {
            return false
        }

        let values = filteredProducts.compactMap { numericValue(for: $0, kind: kind) }
        guard let reference = kind.prefersHigher ? values.max() : values.min() else {
            return false
        }

        return abs(reference - currentValue) < 0.0001
    }

    private func comparisonRows(for products: [FinancialProduct]) -> [ProductComparisonRow] {
        let metricRows: [(String, CompareTableColumnKind)] = [
            ("Entidad", .entity),
            ("Producto", .product),
            ("Comisión", .monthlyFee),
            ("Tasa", .rate),
            ("Costo relevante", .annualCost),
            ("Requisito mínimo", .minimumRequirement),
            ("Actualizado", .updated)
        ]

        var rows = metricRows.map { title, kind in
            ProductComparisonRow(
                id: kind.description,
                title: title,
                values: products.map { product in
                    ProductComparisonValue(
                        id: "\(kind.description)-\(product.id)",
                        productID: product.id,
                        value: displayValue(
                            for: product,
                            column: .init(kind: kind, shortTitle: title, longTitle: title)
                        ),
                        highlighted: isBest(product, for: kind)
                    )
                }
            )
        }

        rows.append(
            ProductComparisonRow(
                id: "summary",
                title: "Resumen",
                values: products.map { product in
                    ProductComparisonValue(
                        id: "summary-\(product.id)",
                        productID: product.id,
                        value: product.summary,
                        highlighted: false
                    )
                }
            )
        )

        rows.append(
            ProductComparisonRow(
                id: "highlights",
                title: "Claves",
                values: products.map { product in
                    ProductComparisonValue(
                        id: "highlights-\(product.id)",
                        productID: product.id,
                        value: product.highlights.prefix(3).joined(separator: " · "),
                        highlighted: false
                    )
                }
            )
        )

        return rows
    }

    private func numericValue(for product: FinancialProduct, kind: CompareTableColumnKind) -> Double? {
        switch kind {
        case .monthlyFee:
            return product.monthlyFee
        case .rate:
            return product.rate
        case .annualCost:
            return product.annualCost
        case .minimumRequirement:
            return product.minimumIncome
        case .compare, .entity, .product, .updated, .favorite:
            return nil
        }
    }
}

private extension CompareTableColumnKind {
    var description: String {
        switch self {
        case .compare:
            return "compare"
        case .entity:
            return "entity"
        case .product:
            return "product"
        case .monthlyFee:
            return "monthlyFee"
        case .rate:
            return "rate"
        case .annualCost:
            return "annualCost"
        case .minimumRequirement:
            return "minimumRequirement"
        case .updated:
            return "updated"
        case .favorite:
            return "favorite"
        }
    }
}
