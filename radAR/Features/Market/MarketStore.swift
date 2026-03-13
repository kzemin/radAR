import Foundation
import Observation

@MainActor
@Observable
final class MarketStore {
    private let headlineOrder = [
        "fx-usd",
        "variable-5",
        "variable-4",
        "variable-7",
        "variable-8",
        "fx-eur",
        "fx-brl"
    ]

    private let marketService: any MarketServicing
    private let favoritesStore: FavoritesStore

    var state: LoadableState<MarketOverview> = .idle
    var selectedQuoteID: String?
    var selectedRange: MarketRange = .thirtyDays
    var watchlistIDs: Set<String> = []

    init(
        marketService: any MarketServicing,
        favoritesStore: FavoritesStore
    ) {
        self.marketService = marketService
        self.favoritesStore = favoritesStore
    }

    var overviewQuotes: [MarketQuote] {
        state.value?.quotes ?? []
    }

    var overviewIndicators: [MarketIndicator] {
        state.value?.indicators ?? []
    }

    var selectedQuote: MarketQuote? {
        overviewQuotes.first(where: { $0.id == selectedQuoteID }) ?? overviewQuotes.first
    }

    var overviewUpdatedAt: Date? {
        overviewQuotes.compactMap { $0.series.last?.date }.max()
    }

    var overviewTiles: [MarketQuote] {
        let prioritized = headlineOrder.compactMap { id in
            overviewQuotes.first(where: { $0.id == id })
        }

        return prioritized.isEmpty ? Array(overviewQuotes.prefix(6)) : prioritized
    }

    var quoteRows: [MarketQuote] {
        overviewQuotes
    }

    var variableRows: [MarketIndicator] {
        overviewIndicators
    }

    var watchlistCount: Int {
        watchlistIDs.count
    }

    var visibleSeries: [MarketPoint] {
        guard let selectedQuote else {
            return []
        }

        return series(for: selectedQuote, range: selectedRange)
    }

    var selectedMetric: FinancialMetric? {
        selectedQuote.map(metric(for:))
    }

    var selectedAbsoluteChange: FinancialChange? {
        selectedQuote.flatMap(dayAbsoluteChange(for:))
    }

    var selectedRangeAbsoluteChange: FinancialChange? {
        selectedQuote.flatMap { quote in
            rangeAbsoluteChange(for: quote, range: selectedRange)
        }
    }

    var selectedRangePercentageChange: Double? {
        selectedQuote.flatMap { quote in
            rangePercentageChange(for: quote, range: selectedRange)
        }
    }

    var watchlistQuotes: [MarketQuote] {
        overviewQuotes.filter { watchlistIDs.contains($0.id) }
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
            async let overviewTask = marketService.fetchOverview()
            async let watchlistTask = favoritesStore.favorites(in: .marketWatchlist)

            let overview = try await overviewTask
            watchlistIDs = await watchlistTask
            let defaultWatchlist = overview.quotes.filter { watchlistIDs.contains($0.id) }
            selectedQuoteID = resolvedSelectedQuoteID(
                from: overview.quotes,
                persistedSelection: selectedQuoteID,
                watchlist: defaultWatchlist
            )
            state = overview.quotes.isEmpty
                ? .empty("No encontramos cotizaciones para mostrar.")
                : .loaded(overview)
        } catch let error as AppError {
            state = .failed(error)
        } catch {
            state = .failed(.service("No pudimos cargar el mercado."))
        }
    }

    func selectQuote(_ quote: MarketQuote) {
        selectedQuoteID = quote.id
    }

    func toggleWatchlist(_ quote: MarketQuote) {
        Task { @MainActor in
            watchlistIDs = await favoritesStore.toggle(quote.id, in: .marketWatchlist)
        }
    }

    func isInWatchlist(_ quote: MarketQuote) -> Bool {
        watchlistIDs.contains(quote.id)
    }

    func metric(for quote: MarketQuote) -> FinancialMetric {
        if isRateQuote(quote) {
            return FinancialMetric(value: quote.price, format: .percentage)
        }

        return FinancialMetric(value: quote.price, format: .currency(code: quote.currencyCode))
    }

    func metric(for indicator: MarketIndicator) -> FinancialMetric {
        FinancialMetric(value: indicator.value, format: .number(unit: indicator.unit))
    }

    func dayAbsoluteChange(for quote: MarketQuote) -> FinancialChange? {
        guard quote.series.count >= 2 else {
            return nil
        }

        let latest = quote.series[quote.series.count - 1].value
        let previous = quote.series[quote.series.count - 2].value
        let delta = latest - previous

        return metricChange(for: quote, value: delta)
    }

    func updatedAt(for quote: MarketQuote) -> Date {
        quote.series.last?.date ?? .now
    }

    func series(for quote: MarketQuote, range: MarketRange) -> [MarketPoint] {
        let latestDate = quote.series.last?.date ?? .now
        let cutoff = range.cutoffDate(reference: latestDate)
        return quote.series.filter { $0.date >= cutoff }
    }

    func sparklinePoints(for quote: MarketQuote) -> [MarketPoint] {
        Array(series(for: quote, range: .thirtyDays).suffix(24))
    }

    func rangeAbsoluteChange(
        for quote: MarketQuote,
        range: MarketRange
    ) -> FinancialChange? {
        let series = series(for: quote, range: range)

        guard
            let first = series.first?.value,
            let last = series.last?.value
        else {
            return nil
        }

        return metricChange(for: quote, value: last - first)
    }

    func rangePercentageChange(
        for quote: MarketQuote,
        range: MarketRange
    ) -> Double? {
        let series = series(for: quote, range: range)

        guard
            let first = series.first?.value,
            let last = series.last?.value,
            first != 0
        else {
            return nil
        }

        return ((last - first) / first) * 100
    }

    func rangeHighLow(
        for quote: MarketQuote,
        range: MarketRange
    ) -> (high: Double, low: Double)? {
        let values = series(for: quote, range: range).map(\.value)

        guard
            let high = values.max(),
            let low = values.min()
        else {
            return nil
        }

        return (high, low)
    }

    func rangeStartValue(
        for quote: MarketQuote,
        range: MarketRange
    ) -> Double? {
        series(for: quote, range: range).first?.value
    }

    func marketTagStyle(for quote: MarketQuote) -> StatusChipStyle {
        switch quote.market.lowercased() {
        case "fx":
            return .live
        case "bcra":
            return .accent
        case "tasas":
            return .warning
        case "bonos":
            return .live
        default:
            return .neutral
        }
    }

    private func isRateQuote(_ quote: MarketQuote) -> Bool {
        quote.market == "Tasas" || quote.symbol.localizedCaseInsensitiveContains("badlar")
    }

    private func metricChange(for quote: MarketQuote, value: Double) -> FinancialChange {
        if isRateQuote(quote) {
            return FinancialChange(value: value, format: .percentage)
        }

        return FinancialChange(value: value, format: .currency(code: quote.currencyCode))
    }

    private func resolvedSelectedQuoteID(
        from quotes: [MarketQuote],
        persistedSelection: String?,
        watchlist: [MarketQuote]
    ) -> String? {
        if let persistedSelection, quotes.contains(where: { $0.id == persistedSelection }) {
            return persistedSelection
        }

        let prioritized = headlineOrder.compactMap { id in
            quotes.first(where: { $0.id == id })
        }

        return watchlist.first?.id ?? prioritized.first?.id ?? quotes.first?.id
    }
}
