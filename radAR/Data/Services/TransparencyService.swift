import Foundation

protocol TransparencyServicing {
    func fetchProducts(for category: ProductCategory) async throws -> [FinancialProduct]
}
