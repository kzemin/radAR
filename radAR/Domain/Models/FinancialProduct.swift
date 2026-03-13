import Foundation

struct FinancialProduct: Identifiable, Hashable {
    let id: String
    let name: String
    let institution: String
    let category: ProductCategory
    let currencyCode: String
    let monthlyFee: Double?
    let rate: Double?
    let annualCost: Double?
    let minimumIncome: Double?
    let updatedAt: Date
    let summary: String
    let highlights: [String]
}
