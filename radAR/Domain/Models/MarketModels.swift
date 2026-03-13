import Foundation

struct MarketOverview: Hashable {
    let quotes: [MarketQuote]
    let indicators: [MarketIndicator]
}

struct MarketQuote: Identifiable, Hashable {
    let id: String
    let name: String
    let symbol: String
    let market: String
    let price: Double
    let changePercentage: Double
    let currencyCode: String
    let series: [MarketPoint]
}

struct MarketIndicator: Identifiable, Hashable {
    let id: String
    let name: String
    let value: Double
    let unit: String
    let changePercentage: Double?
}

struct MarketPoint: Identifiable, Hashable {
    let id: String
    let date: Date
    let value: Double
}

enum MarketRange: String, CaseIterable, Identifiable {
    case sevenDays = "7D"
    case thirtyDays = "30D"
    case ninetyDays = "90D"
    case oneYear = "1Y"

    var id: Self { self }

    func cutoffDate(reference: Date = .now) -> Date {
        let daysBack: Int

        switch self {
        case .sevenDays:
            daysBack = 7
        case .thirtyDays:
            daysBack = 30
        case .ninetyDays:
            daysBack = 90
        case .oneYear:
            daysBack = 365
        }

        return Calendar.current.date(byAdding: .day, value: -daysBack, to: reference) ?? reference
    }
}
