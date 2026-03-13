import Foundation
import Observation

@MainActor
@Observable
final class HomeStore {
    private let transparencyService: any TransparencyServicing
    private let marketService: any MarketServicing
    private let favoritesStore: FavoritesStore
    private let settingsStorage: SettingsStorage

    var state: LoadableState<HomeDashboard> = .idle
    var usesCompactNumbers = true

    init(
        transparencyService: any TransparencyServicing,
        marketService: any MarketServicing,
        favoritesStore: FavoritesStore,
        settingsStorage: SettingsStorage
    ) {
        self.transparencyService = transparencyService
        self.marketService = marketService
        self.favoritesStore = favoritesStore
        self.settingsStorage = settingsStorage
    }

    func loadIfNeeded() async {
        guard case .idle = state else {
            return
        }

        await refresh()
    }

    func refresh() async {
        let settings = settingsStorage.load()
        usesCompactNumbers = settings.useCompactNumbers
        state = .loading

        do {
            async let overviewTask = marketService.fetchOverview()
            async let watchlistTask = favoritesStore.favorites(in: .marketWatchlist)
            async let savingsTask = transparencyService.fetchProducts(for: .savingsAccount)
            async let packagesTask = transparencyService.fetchProducts(for: .package)
            async let termDepositsTask = transparencyService.fetchProducts(for: .termDeposit)
            async let personalLoansTask = transparencyService.fetchProducts(for: .personalLoan)
            async let creditCardsTask = transparencyService.fetchProducts(for: .creditCard)

            let overview = try await overviewTask
            let watchlistIDs = await watchlistTask
            let savingsAccounts = try await savingsTask
            let packages = try await packagesTask
            let termDeposits = try await termDepositsTask
            let personalLoans = try await personalLoansTask
            let creditCards = try await creditCardsTask

            let macroSummary = makeMacroSummary(from: overview)
            let watchlist = makeWatchlist(
                from: overview,
                watchlistIDs: watchlistIDs,
                prioritizeWatchlist: settings.showWatchlistFirstOnHome
            )
            let quickActions = makeQuickActions(
                savingsAccounts: savingsAccounts,
                packages: packages,
                termDeposits: termDeposits,
                personalLoans: personalLoans,
                creditCards: creditCards
            )
            let featuredProducts = makeFeaturedProducts(
                savingsAccounts: savingsAccounts,
                packages: packages,
                termDeposits: termDeposits,
                personalLoans: personalLoans,
                creditCards: creditCards
            )
            let movers = makeMovers(from: overview)

            guard !macroSummary.isEmpty, !watchlist.isEmpty else {
                state = .empty("Todavía no hay suficiente información para armar el monitor principal.")
                return
            }

            state = .loaded(
                HomeDashboard(
                    macroSummary: macroSummary,
                    watchlist: watchlist,
                    quickActions: quickActions,
                    featuredProducts: featuredProducts,
                    movers: movers,
                    updatedAt: overview.quotes.compactMap { $0.series.last?.date }.max() ?? .now
                )
            )
        } catch let error as AppError {
            state = .failed(error)
        } catch {
            state = .failed(.service("No pudimos cargar el monitor global."))
        }
    }

    private func makeMacroSummary(from overview: MarketOverview) -> [HomeMacroMetric] {
        let quoteItems = overview.quotes.prefix(4).map { quote in
            HomeMacroMetric(
                id: quote.id,
                title: quote.symbol,
                subtitle: quote.name,
                badge: badge(forMarket: quote.market),
                metric: metric(for: quote),
                changePercentage: quote.changePercentage,
                points: Array(quote.series.suffix(24))
            )
        }

        let indicatorItems = overview.indicators.prefix(2).map { indicator in
            HomeMacroMetric(
                id: indicator.id,
                title: indicator.name,
                subtitle: indicator.unit,
                badge: "MACRO",
                metric: FinancialMetric(value: indicator.value, format: .number(unit: indicator.unit)),
                changePercentage: indicator.changePercentage,
                points: []
            )
        }

        return Array(quoteItems) + indicatorItems
    }

    private func makeWatchlist(
        from overview: MarketOverview,
        watchlistIDs: Set<String>,
        prioritizeWatchlist: Bool
    ) -> [HomeMarketLine] {
        let watchedQuotes = overview.quotes.filter { watchlistIDs.contains($0.id) }
        let sourceQuotes: [MarketQuote]

        if prioritizeWatchlist, !watchedQuotes.isEmpty {
            sourceQuotes = watchedQuotes
        } else {
            sourceQuotes = overview.quotes
                .sorted { abs($0.changePercentage) > abs($1.changePercentage) }
                .prefix(5)
                .map { $0 }
        }

        return sourceQuotes.map(makeMarketLine)
    }

    private func makeQuickActions(
        savingsAccounts: [FinancialProduct],
        packages: [FinancialProduct],
        termDeposits: [FinancialProduct],
        personalLoans: [FinancialProduct],
        creditCards: [FinancialProduct]
    ) -> [HomeQuickAction] {
        [
            HomeQuickAction(
                id: "compare-savings",
                title: ProductCategory.savingsAccount.rawValue,
                subtitle: "Mantenimiento desde",
                metric: FinancialMetric(
                    value: lowestMonthlyFee(in: savingsAccounts),
                    format: .currency(code: "ARS")
                ),
                detail: "\(savingsAccounts.count) productos",
                category: .savingsAccount
            ),
            HomeQuickAction(
                id: "compare-package",
                title: ProductCategory.package.rawValue,
                subtitle: "Fee mensual desde",
                metric: FinancialMetric(
                    value: lowestMonthlyFee(in: packages),
                    format: .currency(code: "ARS")
                ),
                detail: "\(packages.count) productos",
                category: .package
            ),
            HomeQuickAction(
                id: "compare-term-deposits",
                title: ProductCategory.termDeposit.rawValue,
                subtitle: "Top TNA del panel",
                metric: FinancialMetric(
                    value: highestRate(in: termDeposits),
                    format: .percentage
                ),
                detail: "\(termDeposits.count) productos",
                category: .termDeposit
            ),
            HomeQuickAction(
                id: "compare-personal-loans",
                title: ProductCategory.personalLoan.rawValue,
                subtitle: "Menor CFT observado",
                metric: FinancialMetric(
                    value: lowestAnnualCost(in: personalLoans),
                    format: .percentage
                ),
                detail: "\(personalLoans.count) productos",
                category: .personalLoan
            ),
            HomeQuickAction(
                id: "compare-credit-cards",
                title: ProductCategory.creditCard.rawValue,
                subtitle: "Fee mensual desde",
                metric: FinancialMetric(
                    value: lowestMonthlyFee(in: creditCards),
                    format: .currency(code: "ARS")
                ),
                detail: "\(creditCards.count) productos",
                category: .creditCard
            )
        ]
    }

    private func makeFeaturedProducts(
        savingsAccounts: [FinancialProduct],
        packages: [FinancialProduct],
        termDeposits: [FinancialProduct],
        personalLoans: [FinancialProduct],
        creditCards: [FinancialProduct]
    ) -> [HomeFeaturedProduct] {
        [
            featuredProduct(
                from: savingsAccounts,
                label: "Mantenimiento 0",
                category: .savingsAccount,
                primaryMetric: { FinancialMetric(value: $0.monthlyFee, format: .currency(code: $0.currencyCode)) },
                secondaryMetric: nil,
                sort: { ($0.monthlyFee ?? Double.greatestFiniteMagnitude) < ($1.monthlyFee ?? Double.greatestFiniteMagnitude) }
            ),
            featuredProduct(
                from: packages,
                label: "Paquete destacado",
                category: .package,
                primaryMetric: { FinancialMetric(value: $0.monthlyFee, format: .currency(code: $0.currencyCode)) },
                secondaryMetric: { FinancialMetric(value: $0.minimumIncome, format: .currency(code: $0.currencyCode)) },
                sort: { ($0.monthlyFee ?? Double.greatestFiniteMagnitude) < ($1.monthlyFee ?? Double.greatestFiniteMagnitude) }
            ),
            featuredProduct(
                from: termDeposits,
                label: "Mejor tasa",
                category: .termDeposit,
                primaryMetric: { FinancialMetric(value: $0.rate, format: .percentage) },
                secondaryMetric: { FinancialMetric(value: $0.minimumIncome, format: .currency(code: $0.currencyCode)) },
                sort: { ($0.rate ?? 0) > ($1.rate ?? 0) }
            ),
            featuredProduct(
                from: personalLoans,
                label: "Menor CFT",
                category: .personalLoan,
                primaryMetric: { FinancialMetric(value: $0.annualCost, format: .percentage) },
                secondaryMetric: { FinancialMetric(value: $0.rate, format: .percentage) },
                sort: { ($0.annualCost ?? Double.greatestFiniteMagnitude) < ($1.annualCost ?? Double.greatestFiniteMagnitude) }
            ),
            featuredProduct(
                from: creditCards,
                label: "Costo más bajo",
                category: .creditCard,
                primaryMetric: { FinancialMetric(value: $0.monthlyFee, format: .currency(code: $0.currencyCode)) },
                secondaryMetric: { FinancialMetric(value: $0.annualCost, format: .percentage) },
                sort: { ($0.monthlyFee ?? Double.greatestFiniteMagnitude) < ($1.monthlyFee ?? Double.greatestFiniteMagnitude) }
            )
        ]
        .compactMap { $0 }
    }

    private func makeMovers(from overview: MarketOverview) -> [HomeMarketLine] {
        overview.quotes
            .sorted { abs($0.changePercentage) > abs($1.changePercentage) }
            .prefix(4)
            .map(makeMarketLine)
    }

    private func makeMarketLine(from quote: MarketQuote) -> HomeMarketLine {
        HomeMarketLine(
            id: quote.id,
            symbol: quote.symbol,
            name: quote.name,
            market: quote.market,
            metric: metric(for: quote),
            changePercentage: quote.changePercentage,
            points: Array(quote.series.suffix(20)),
            updatedAt: quote.series.last?.date ?? .now
        )
    }

    private func featuredProduct(
        from products: [FinancialProduct],
        label: String,
        category: ProductCategory,
        primaryMetric: (FinancialProduct) -> FinancialMetric,
        secondaryMetric: ((FinancialProduct) -> FinancialMetric?)?,
        sort: (FinancialProduct, FinancialProduct) -> Bool
    ) -> HomeFeaturedProduct? {
        guard let product = products.sorted(by: sort).first else {
            return nil
        }

        return HomeFeaturedProduct(
            id: product.id,
            label: label,
            title: product.name,
            institution: product.institution,
            category: category,
            primaryMetric: primaryMetric(product),
            secondaryMetric: secondaryMetric?(product),
            updatedAt: product.updatedAt
        )
    }

    private func metric(for quote: MarketQuote) -> FinancialMetric {
        let isRateSeries = quote.market == "Tasas"
            || quote.symbol.localizedCaseInsensitiveContains("badlar")
            || quote.symbol.localizedCaseInsensitiveContains("tm20")

        if isRateSeries {
            return FinancialMetric(value: quote.price, format: .percentage)
        }

        return FinancialMetric(
            value: quote.price,
            format: .currency(code: quote.currencyCode)
        )
    }

    private func badge(forMarket market: String) -> String {
        switch market.lowercased() {
        case "tasas":
            return "RATE"
        case "fx", "bonos":
            return "FX"
        case "bcra":
            return "BCRA"
        case "mayorista":
            return "SPOT"
        default:
            return "MKT"
        }
    }

    private func lowestMonthlyFee(in products: [FinancialProduct]) -> Double? {
        products.min { ($0.monthlyFee ?? Double.greatestFiniteMagnitude) < ($1.monthlyFee ?? Double.greatestFiniteMagnitude) }?.monthlyFee
    }

    private func highestRate(in products: [FinancialProduct]) -> Double? {
        products.max { ($0.rate ?? 0) < ($1.rate ?? 0) }?.rate
    }

    private func lowestAnnualCost(in products: [FinancialProduct]) -> Double? {
        products.min { ($0.annualCost ?? Double.greatestFiniteMagnitude) < ($1.annualCost ?? Double.greatestFiniteMagnitude) }?.annualCost
    }
}
