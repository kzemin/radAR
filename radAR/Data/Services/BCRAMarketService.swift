import Foundation

struct BCRAMarketService: MarketServicing {
    private let apiClient: any APIClient

    init(apiClient: any APIClient) {
        self.apiClient = apiClient
    }

    func fetchOverview() async throws -> MarketOverview {
        async let exchangeRateSnapshotTask = fetchExchangeRateSnapshot()
        async let variableSnapshotsTask = fetchVariableSnapshots()

        let exchangeRateSnapshot = try await exchangeRateSnapshotTask
        let variableSnapshots = try await variableSnapshotsTask

        let exchangeRateHistoryByCode = try await fetchExchangeRateHistory()
        let variableSeriesByID = try await fetchVariableSeries()

        let overview = MarketMapper.mapOverview(
            quoteDefinitions: quoteDefinitions,
            indicatorDefinitions: indicatorDefinitions,
            exchangeRateSnapshot: exchangeRateSnapshot,
            exchangeRateHistoryByCode: exchangeRateHistoryByCode,
            variableSnapshots: variableSnapshots,
            variableSeriesByID: variableSeriesByID
        )

        guard !overview.quotes.isEmpty else {
            throw AppError.service("No encontramos cotizaciones públicas para armar el monitor de mercado.")
        }

        return overview
    }

    private var quoteDefinitions: [BCRAMarketQuoteDefinition] {
        [
            .init(
                id: "fx-usd",
                source: .exchangeRate(code: "USD"),
                symbol: "USD",
                displayName: "Dólar oficial de referencia",
                market: "FX",
                currencyCode: "ARS"
            ),
            .init(
                id: "variable-5",
                source: .monetaryVariable(id: 5),
                symbol: "USD MAYORISTA",
                displayName: "Tipo de cambio mayorista",
                market: "FX",
                currencyCode: "ARS"
            ),
            .init(
                id: "variable-4",
                source: .monetaryVariable(id: 4),
                symbol: "USD MINORISTA",
                displayName: "Tipo de cambio minorista",
                market: "FX",
                currencyCode: "ARS"
            ),
            .init(
                id: "variable-7",
                source: .monetaryVariable(id: 7),
                symbol: "BADLAR",
                displayName: "BADLAR bancos privados",
                market: "Tasas",
                currencyCode: "ARS"
            ),
            .init(
                id: "variable-8",
                source: .monetaryVariable(id: 8),
                symbol: "TM20",
                displayName: "TM20 bancos privados",
                market: "Tasas",
                currencyCode: "ARS"
            ),
            .init(
                id: "fx-eur",
                source: .exchangeRate(code: "EUR"),
                symbol: "EUR",
                displayName: "Euro",
                market: "FX",
                currencyCode: "ARS"
            ),
            .init(
                id: "fx-brl",
                source: .exchangeRate(code: "BRL"),
                symbol: "BRL",
                displayName: "Real brasileño",
                market: "FX",
                currencyCode: "ARS"
            )
        ]
    }

    private var indicatorDefinitions: [BCRAMarketIndicatorDefinition] {
        [
            .init(id: "indicator-1", variableID: 1, displayName: "Reservas internacionales", unitOverride: "M USD"),
            .init(id: "indicator-15", variableID: 15, displayName: "Base monetaria", unitOverride: "M ARS"),
            .init(id: "indicator-16", variableID: 16, displayName: "Circulación monetaria", unitOverride: "M ARS"),
            .init(id: "indicator-24", variableID: 24, displayName: "Depósitos a plazo", unitOverride: "M ARS"),
            .init(id: "indicator-29", variableID: 29, displayName: "Inflación esperada 12M", unitOverride: "% i.a.")
        ]
    }

    private var quoteVariableIDs: [Int] {
        Array(
            Set(
                quoteDefinitions.compactMap { definition -> Int? in
                    guard case let .monetaryVariable(id) = definition.source else {
                        return nil
                    }

                    return id
                }
            )
        )
        .sorted()
    }

    private var snapshotVariableIDs: [Int] {
        let indicatorIDs = indicatorDefinitions.map(\.variableID)
        return Array(Set(quoteVariableIDs + indicatorIDs)).sorted()
    }

    private func fetchExchangeRateSnapshot() async throws -> BCRAExchangeRatesSnapshotDTO {
        let request = APIRequest<BCRAEnvelopeDTO<BCRAExchangeRatesSnapshotDTO>>(
            path: "estadisticascambiarias/v1.0/cotizaciones",
            headers: defaultHeaders,
            cachePolicy: .networkWithCacheFallback(ttl: 60 * 15)
        )

        let response = try await apiClient.send(request)
        try validateStatus(response.status, errorMessages: response.errorMessages, context: "cotizaciones cambiarias")
        return response.results
    }

    private func fetchVariableSnapshots() async throws -> [BCRAMonetaryVariableDTO] {
        let request = APIRequest<BCRAEnvelopeDTO<[BCRAMonetaryVariableDTO]>>(
            path: "estadisticas/v4.0/monetarias",
            queryItems: [
                URLQueryItem(name: "limit", value: "100")
            ],
            headers: defaultHeaders,
            cachePolicy: .networkWithCacheFallback(ttl: 60 * 15)
        )

        let response = try await apiClient.send(request)
        try validateStatus(response.status, errorMessages: response.errorMessages, context: "variables monetarias")
        let byID = Dictionary(uniqueKeysWithValues: response.results.map { ($0.idVariable, $0) })
        return snapshotVariableIDs.compactMap { byID[$0] }
    }

    private func fetchExchangeRateHistory() async throws -> [String: [BCRAExchangeRateHistoryEntryDTO]] {
        try await withThrowingTaskGroup(of: (String, [BCRAExchangeRateHistoryEntryDTO]).self) { group in
            for definition in quoteDefinitions {
                guard case let .exchangeRate(code) = definition.source else {
                    continue
                }

                group.addTask {
                    let history = try await fetchExchangeRateHistory(for: code)
                    return (code, history)
                }
            }

            var results: [String: [BCRAExchangeRateHistoryEntryDTO]] = [:]

            for try await (code, history) in group {
                results[code] = history
            }

            return results
        }
    }

    private func fetchVariableSeries() async throws -> [Int: [BCRAMonetaryPointDTO]] {
        try await withThrowingTaskGroup(of: (Int, [BCRAMonetaryPointDTO]).self) { group in
            for id in quoteVariableIDs {
                group.addTask {
                    let history = try await fetchVariableSeries(for: id)
                    return (id, history)
                }
            }

            var results: [Int: [BCRAMonetaryPointDTO]] = [:]

            for try await (id, history) in group {
                results[id] = history
            }

            return results
        }
    }

    private func fetchExchangeRateHistory(for code: String) async throws -> [BCRAExchangeRateHistoryEntryDTO] {
        let request = APIRequest<BCRAEnvelopeDTO<[BCRAExchangeRateHistoryEntryDTO]>>(
            path: "estadisticascambiarias/v1.0/cotizaciones/\(code)",
            queryItems: [
                URLQueryItem(name: "fechadesde", value: oneYearAgoString),
                URLQueryItem(name: "fechahasta", value: todayString)
            ],
            headers: defaultHeaders,
            cachePolicy: .networkWithCacheFallback(ttl: 60 * 20)
        )

        let response = try await apiClient.send(request)
        try validateStatus(response.status, errorMessages: response.errorMessages, context: "serie cambiaria \(code)")
        return response.results
    }

    private func fetchVariableSeries(for id: Int) async throws -> [BCRAMonetaryPointDTO] {
        let request = APIRequest<BCRAEnvelopeDTO<[BCRAMonetarySeriesDTO]>>(
            path: "estadisticas/v4.0/monetarias/\(id)",
            queryItems: [
                URLQueryItem(name: "desde", value: oneYearAgoString),
                URLQueryItem(name: "hasta", value: todayString)
            ],
            headers: defaultHeaders,
            cachePolicy: .networkWithCacheFallback(ttl: 60 * 20)
        )

        let response = try await apiClient.send(request)
        try validateStatus(response.status, errorMessages: response.errorMessages, context: "serie monetaria \(id)")
        return response.results.first?.detalle ?? []
    }

    private func validateStatus(
        _ status: Int,
        errorMessages: [String]?,
        context: String
    ) throws {
        guard status == 200 else {
            let message = errorMessages?.joined(separator: " ") ?? "La API del BCRA respondió con un estado inválido en \(context)."
            throw AppError.service(message)
        }
    }

    private var defaultHeaders: [String: String] {
        [
            "Accept": "application/json",
            "Accept-Language": "es-AR"
        ]
    }

    private var todayString: String {
        formattedDate(Date())
    }

    private var oneYearAgoString: String {
        let date = Calendar(identifier: .gregorian).date(byAdding: .day, value: -365, to: Date()) ?? Date()
        return formattedDate(date)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
