import Foundation

struct MockTransparencyService: TransparencyServicing {
    func fetchProducts(for category: ProductCategory) async throws -> [FinancialProduct] {
        try await Task.sleep(nanoseconds: 180_000_000)
        return TransparencyProductDTO.samples(for: category).map(TransparencyProductMapper.map)
    }
}
