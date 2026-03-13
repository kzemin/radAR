import Foundation

enum HomeFixtures {
    static var dashboard: HomeDashboard {
        HomeDashboard(
            macroSummary: [
                HomeMacroMetric(
                    id: "usd-oficial",
                    title: "USD OF.",
                    subtitle: "Dólar oficial",
                    badge: "SPOT",
                    metric: FinancialMetric(value: 1_078, format: .currency(code: "ARS")),
                    changePercentage: 0.8,
                    points: points(base: 1_028, drift: 1.7, amplitude: 4.2)
                ),
                HomeMacroMetric(
                    id: "usd-mep",
                    title: "USD MEP",
                    subtitle: "Bonos",
                    badge: "FX",
                    metric: FinancialMetric(value: 1_125, format: .currency(code: "ARS")),
                    changePercentage: -0.4,
                    points: points(base: 1_070, drift: 1.2, amplitude: 6.4)
                ),
                HomeMacroMetric(
                    id: "ccl",
                    title: "CCL",
                    subtitle: "Contado con liqui",
                    badge: "FX",
                    metric: FinancialMetric(value: 1_163, format: .currency(code: "ARS")),
                    changePercentage: 0.3,
                    points: points(base: 1_118, drift: 1.4, amplitude: 7.1)
                ),
                HomeMacroMetric(
                    id: "badlar",
                    title: "BADLAR",
                    subtitle: "Tasa bancos privados",
                    badge: "RATE",
                    metric: FinancialMetric(value: 32.8, format: .percentage),
                    changePercentage: -1.1,
                    points: points(base: 37.9, drift: -0.16, amplitude: 0.8)
                ),
                HomeMacroMetric(
                    id: "riesgo-pais",
                    title: "RIESGO PAIS",
                    subtitle: "pbs",
                    badge: "MACRO",
                    metric: FinancialMetric(value: 718, format: .number(unit: "pbs")),
                    changePercentage: 1.8,
                    points: []
                ),
                HomeMacroMetric(
                    id: "reservas",
                    title: "RESERVAS",
                    subtitle: "M USD",
                    badge: "MACRO",
                    metric: FinancialMetric(value: 28_400, format: .number(unit: "M USD")),
                    changePercentage: 0.9,
                    points: []
                )
            ],
            watchlist: [
                HomeMarketLine(
                    id: "usd-mep",
                    symbol: "USD MEP",
                    name: "Dólar MEP",
                    market: "Bonos",
                    metric: FinancialMetric(value: 1_125, format: .currency(code: "ARS")),
                    changePercentage: -0.4,
                    points: points(base: 1_070, drift: 1.2, amplitude: 6.4),
                    updatedAt: .now
                ),
                HomeMarketLine(
                    id: "usd-ccl",
                    symbol: "CCL",
                    name: "Contado con liqui",
                    market: "Bonos",
                    metric: FinancialMetric(value: 1_163, format: .currency(code: "ARS")),
                    changePercentage: 0.3,
                    points: points(base: 1_118, drift: 1.4, amplitude: 7.1),
                    updatedAt: .now
                ),
                HomeMarketLine(
                    id: "usd-oficial",
                    symbol: "USD OF.",
                    name: "Dólar oficial",
                    market: "FX",
                    metric: FinancialMetric(value: 1_078, format: .currency(code: "ARS")),
                    changePercentage: 0.8,
                    points: points(base: 1_028, drift: 1.7, amplitude: 4.2),
                    updatedAt: .now
                ),
                HomeMarketLine(
                    id: "badlar",
                    symbol: "BADLAR",
                    name: "Tasa BADLAR",
                    market: "Tasas",
                    metric: FinancialMetric(value: 32.8, format: .percentage),
                    changePercentage: -1.1,
                    points: points(base: 37.9, drift: -0.16, amplitude: 0.8),
                    updatedAt: .now
                ),
                HomeMarketLine(
                    id: "reservas",
                    symbol: "RES",
                    name: "Reservas brutas",
                    market: "Macro",
                    metric: FinancialMetric(value: 28_400, format: .number(unit: "M USD")),
                    changePercentage: 0.9,
                    points: points(base: 27_900, drift: 19.5, amplitude: 74),
                    updatedAt: .now
                )
            ],
            quickActions: [
                HomeQuickAction(
                    id: "savings",
                    title: ProductCategory.savingsAccount.rawValue,
                    subtitle: "Mantenimiento desde",
                    metric: FinancialMetric(value: 0, format: .currency(code: "ARS")),
                    detail: "3 productos",
                    category: .savingsAccount
                ),
                HomeQuickAction(
                    id: "packages",
                    title: ProductCategory.package.rawValue,
                    subtitle: "Fee mensual desde",
                    metric: FinancialMetric(value: 7_300, format: .currency(code: "ARS")),
                    detail: "3 productos",
                    category: .package
                ),
                HomeQuickAction(
                    id: "term-deposits",
                    title: ProductCategory.termDeposit.rawValue,
                    subtitle: "Top TNA del panel",
                    metric: FinancialMetric(value: 31.5, format: .percentage),
                    detail: "3 productos",
                    category: .termDeposit
                ),
                HomeQuickAction(
                    id: "personal-loans",
                    title: ProductCategory.personalLoan.rawValue,
                    subtitle: "Menor CFT observado",
                    metric: FinancialMetric(value: 97.6, format: .percentage),
                    detail: "3 productos",
                    category: .personalLoan
                ),
                HomeQuickAction(
                    id: "credit-cards",
                    title: ProductCategory.creditCard.rawValue,
                    subtitle: "Fee mensual desde",
                    metric: FinancialMetric(value: 3_200, format: .currency(code: "ARS")),
                    detail: "3 productos",
                    category: .creditCard
                )
            ],
            featuredProducts: [
                HomeFeaturedProduct(
                    id: "galicia-move",
                    label: "Mantenimiento 0",
                    title: "Caja Galicia Move",
                    institution: "Galicia",
                    category: .savingsAccount,
                    primaryMetric: FinancialMetric(value: 0, format: .currency(code: "ARS")),
                    secondaryMetric: nil,
                    updatedAt: .now
                ),
                HomeFeaturedProduct(
                    id: "patagonia-plus",
                    label: "Paquete destacado",
                    title: "Patagonia Plus",
                    institution: "Banco Patagonia",
                    category: .package,
                    primaryMetric: FinancialMetric(value: 7_300, format: .currency(code: "ARS")),
                    secondaryMetric: FinancialMetric(value: 1_300_000, format: .currency(code: "ARS")),
                    updatedAt: .now
                ),
                HomeFeaturedProduct(
                    id: "pf-nacion",
                    label: "Mejor tasa",
                    title: "Plazo fijo tradicional 30 dias",
                    institution: "Banco Nación",
                    category: .termDeposit,
                    primaryMetric: FinancialMetric(value: 31.5, format: .percentage),
                    secondaryMetric: FinancialMetric(value: 0, format: .currency(code: "ARS")),
                    updatedAt: .now
                ),
                HomeFeaturedProduct(
                    id: "prestamo-patagonia",
                    label: "Menor CFT",
                    title: "Préstamo Flex",
                    institution: "Banco Patagonia",
                    category: .personalLoan,
                    primaryMetric: FinancialMetric(value: 97.6, format: .percentage),
                    secondaryMetric: FinancialMetric(value: 65.4, format: .percentage),
                    updatedAt: .now
                ),
                HomeFeaturedProduct(
                    id: "nativa-master",
                    label: "Costo mas bajo",
                    title: "Mastercard Nativa",
                    institution: "Banco Nación",
                    category: .creditCard,
                    primaryMetric: FinancialMetric(value: 3_200, format: .currency(code: "ARS")),
                    secondaryMetric: FinancialMetric(value: 113.2, format: .percentage),
                    updatedAt: .now
                )
            ],
            movers: [
                HomeMarketLine(
                    id: "badlar-mover",
                    symbol: "BADLAR",
                    name: "Tasa BADLAR",
                    market: "Tasas",
                    metric: FinancialMetric(value: 32.8, format: .percentage),
                    changePercentage: -1.1,
                    points: points(base: 37.9, drift: -0.16, amplitude: 0.8),
                    updatedAt: .now
                ),
                HomeMarketLine(
                    id: "usd-oficial-mover",
                    symbol: "USD OF.",
                    name: "Dólar oficial",
                    market: "FX",
                    metric: FinancialMetric(value: 1_078, format: .currency(code: "ARS")),
                    changePercentage: 0.8,
                    points: points(base: 1_028, drift: 1.7, amplitude: 4.2),
                    updatedAt: .now
                ),
                HomeMarketLine(
                    id: "ccl-mover",
                    symbol: "CCL",
                    name: "Contado con liqui",
                    market: "Bonos",
                    metric: FinancialMetric(value: 1_163, format: .currency(code: "ARS")),
                    changePercentage: 0.3,
                    points: points(base: 1_118, drift: 1.4, amplitude: 7.1),
                    updatedAt: .now
                ),
                HomeMarketLine(
                    id: "usd-mep-mover",
                    symbol: "USD MEP",
                    name: "Dólar MEP",
                    market: "Bonos",
                    metric: FinancialMetric(value: 1_125, format: .currency(code: "ARS")),
                    changePercentage: -0.4,
                    points: points(base: 1_070, drift: 1.2, amplitude: 6.4),
                    updatedAt: .now
                )
            ],
            updatedAt: .now
        )
    }

    @MainActor
    static func previewStore() -> HomeStore {
        let suiteName = "radar.home.preview"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defaults.removePersistentDomain(forName: suiteName)

        let settingsStorage = SettingsStorage(defaults: defaults)
        let store = HomeStore(
            transparencyService: MockTransparencyService(),
            marketService: MockMarketService(),
            favoritesStore: FavoritesStore(defaults: defaults),
            settingsStorage: settingsStorage
        )

        store.usesCompactNumbers = true
        store.state = .loaded(dashboard)
        return store
    }

    private static func points(
        base: Double,
        drift: Double,
        amplitude: Double,
        count: Int = 24
    ) -> [MarketPoint] {
        (0..<count).map { index in
            let date = Calendar.current.date(byAdding: .day, value: -(count - index), to: .now) ?? .now
            let seasonal = sin(Double(index) / 4.2) * amplitude
            let micro = cos(Double(index) / 2.6) * (amplitude * 0.24)

            return MarketPoint(
                id: "point-\(base)-\(index)",
                date: date,
                value: max(0.1, base + (Double(index) * drift) + seasonal + micro)
            )
        }
    }
}
