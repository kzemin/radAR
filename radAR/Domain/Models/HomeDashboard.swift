import Foundation

struct HomeDashboard: Hashable {
    let macroSummary: [HomeMacroMetric]
    let watchlist: [HomeMarketLine]
    let quickActions: [HomeQuickAction]
    let featuredProducts: [HomeFeaturedProduct]
    let movers: [HomeMarketLine]
    let updatedAt: Date
}

struct HomeMacroMetric: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let badge: String?
    let metric: FinancialMetric
    let changePercentage: Double?
    let points: [MarketPoint]
}

struct HomeMarketLine: Identifiable, Hashable {
    let id: String
    let symbol: String
    let name: String
    let market: String
    let metric: FinancialMetric
    let changePercentage: Double
    let points: [MarketPoint]
    let updatedAt: Date
}

struct HomeQuickAction: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let metric: FinancialMetric
    let detail: String
    let category: ProductCategory
}

struct HomeFeaturedProduct: Identifiable, Hashable {
    let id: String
    let label: String
    let title: String
    let institution: String
    let category: ProductCategory
    let primaryMetric: FinancialMetric
    let secondaryMetric: FinancialMetric?
    let updatedAt: Date
}
