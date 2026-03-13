import Foundation

struct BCRATransparencyService: TransparencyServicing {
    private let apiClient: any APIClient

    init(apiClient: any APIClient) {
        self.apiClient = apiClient
    }

    func fetchProducts(for category: ProductCategory) async throws -> [FinancialProduct] {
        switch category {
        case .savingsAccount:
            let rows: [BCRASavingsAccountDTO] = try await fetchRows(path: "transparencia/v1.0/CajasAhorros")
            return TransparencyProductMapper.mapSavingsAccounts(rows)
        case .package:
            let rows: [BCRAPackageProductDTO] = try await fetchRows(path: "transparencia/v1.0/PaquetesProductos")
            return TransparencyProductMapper.mapPackages(rows)
        case .termDeposit:
            let rows: [BCRATermDepositDTO] = try await fetchRows(path: "transparencia/v1.0/PlazosFijos")
            return TransparencyProductMapper.mapTermDeposits(rows)
        case .personalLoan:
            let rows: [BCRAPersonalLoanDTO] = try await fetchRows(path: "transparencia/v1.0/Prestamos/Personales")
            return TransparencyProductMapper.mapPersonalLoans(rows)
        case .creditCard:
            let rows: [BCRACreditCardDTO] = try await fetchRows(path: "transparencia/v1.0/TarjetasCredito")
            return TransparencyProductMapper.mapCreditCards(rows)
        }
    }

    private func fetchRows<Row: Decodable>(path: String) async throws -> [Row] {
        let request = APIRequest<BCRAEnvelopeDTO<[Row]>>(
            path: path,
            headers: defaultHeaders,
            cachePolicy: .networkWithCacheFallback(ttl: 60 * 60 * 12)
        )

        let response = try await apiClient.send(request)

        guard response.status == 200 else {
            let message = response.errorMessages?.joined(separator: " ") ?? "La API de transparencia del BCRA devolvió una respuesta inválida."
            throw AppError.service(message)
        }

        return response.results
    }

    private var defaultHeaders: [String: String] {
        [
            "Accept": "application/json",
            "Accept-Language": "es-AR"
        ]
    }
}
