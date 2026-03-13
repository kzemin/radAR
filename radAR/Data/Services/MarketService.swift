import Foundation

protocol MarketServicing {
    func fetchOverview() async throws -> MarketOverview
}
