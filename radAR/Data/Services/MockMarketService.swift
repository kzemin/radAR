import Foundation

struct MockMarketService: MarketServicing {
    func fetchOverview() async throws -> MarketOverview {
        try await Task.sleep(nanoseconds: 160_000_000)

        let overviewDTO = MarketFixtures.overview
        let seriesByQuote = Dictionary(
            uniqueKeysWithValues: overviewDTO.quotes.map { quote in
                (quote.id, MarketFixtures.series(for: quote.id))
            }
        )

        return MarketMapper.map(overview: overviewDTO, seriesByQuote: seriesByQuote)
    }
}
