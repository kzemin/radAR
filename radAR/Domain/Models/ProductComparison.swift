import Foundation

struct ProductComparisonSnapshot: Hashable {
    let products: [FinancialProduct]
    let rows: [ProductComparisonRow]
}

struct ProductComparisonRow: Identifiable, Hashable {
    let id: String
    let title: String
    let values: [ProductComparisonValue]
}

struct ProductComparisonValue: Identifiable, Hashable {
    let id: String
    let productID: String
    let value: String
    let highlighted: Bool
}
