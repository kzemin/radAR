import Foundation

struct BCRAMarketQuoteDefinition: Hashable {
    enum Source: Hashable {
        case exchangeRate(code: String)
        case monetaryVariable(id: Int)
    }

    let id: String
    let source: Source
    let symbol: String
    let displayName: String
    let market: String
    let currencyCode: String
}

struct BCRAMarketIndicatorDefinition: Hashable {
    let id: String
    let variableID: Int
    let displayName: String
    let unitOverride: String?
}

enum MarketMapper {
    static func map(
        overview dto: MarketOverviewDTO,
        seriesByQuote: [String: [MarketPointDTO]]
    ) -> MarketOverview {
        MarketOverview(
            quotes: dto.quotes.map { quote in
                MarketQuote(
                    id: quote.id,
                    name: quote.nombre,
                    symbol: quote.simbolo,
                    market: quote.mercado,
                    price: quote.precio,
                    changePercentage: quote.variacion,
                    currencyCode: quote.moneda,
                    series: (seriesByQuote[quote.id] ?? []).enumerated().map { index, point in
                        MarketPoint(
                            id: "\(quote.id)-\(index)",
                            date: point.fecha,
                            value: point.valor
                        )
                    }
                )
            },
            indicators: dto.indicators.map { indicator in
                MarketIndicator(
                    id: indicator.id,
                    name: indicator.nombre,
                    value: indicator.valor,
                    unit: indicator.unidad,
                    changePercentage: indicator.variacion
                )
            }
        )
    }

    static func mapOverview(
        quoteDefinitions: [BCRAMarketQuoteDefinition],
        indicatorDefinitions: [BCRAMarketIndicatorDefinition],
        exchangeRateSnapshot: BCRAExchangeRatesSnapshotDTO,
        exchangeRateHistoryByCode: [String: [BCRAExchangeRateHistoryEntryDTO]],
        variableSnapshots: [BCRAMonetaryVariableDTO],
        variableSeriesByID: [Int: [BCRAMonetaryPointDTO]]
    ) -> MarketOverview {
        let variablesByID = Dictionary(uniqueKeysWithValues: variableSnapshots.map { ($0.idVariable, $0) })

        let quotes = quoteDefinitions.compactMap { definition in
            switch definition.source {
            case let .exchangeRate(code):
                let history = exchangeRateHistoryByCode[code] ?? []
                return mapExchangeQuote(
                    definition: definition,
                    snapshot: exchangeRateSnapshot,
                    history: history
                )
            case let .monetaryVariable(id):
                guard let snapshot = variablesByID[id] else {
                    return nil
                }

                return mapVariableQuote(
                    definition: definition,
                    snapshot: snapshot,
                    series: variableSeriesByID[id] ?? []
                )
            }
        }

        let indicators: [MarketIndicator] = indicatorDefinitions.compactMap { definition -> MarketIndicator? in
            guard let snapshot = variablesByID[definition.variableID] else {
                return nil
            }

            return mapIndicator(
                definition: definition,
                snapshot: snapshot
            )
        }

        return MarketOverview(
            quotes: quotes,
            indicators: indicators
        )
    }

    private static func mapExchangeQuote(
        definition: BCRAMarketQuoteDefinition,
        snapshot: BCRAExchangeRatesSnapshotDTO,
        history: [BCRAExchangeRateHistoryEntryDTO]
    ) -> MarketQuote? {
        let latestQuote = snapshot.detalle.first(where: { $0.codigoMoneda == exchangeCode(for: definition) })
        let historicalPoints = history
            .compactMap { entry -> MarketPoint? in
                guard let quote = entry.detalle.first(where: { $0.codigoMoneda == exchangeCode(for: definition) }) else {
                    return nil
                }

                return MarketPoint(
                    id: "\(definition.id)-\(entry.fecha.timeIntervalSince1970)",
                    date: entry.fecha,
                    value: quote.tipoCotizacion ?? 0
                )
            }
            .sorted { $0.date < $1.date }

        let points: [MarketPoint]

        if historicalPoints.isEmpty, let latestValue = latestQuote?.tipoCotizacion {
            points = [
                MarketPoint(
                    id: "\(definition.id)-snapshot",
                    date: snapshot.fecha,
                    value: latestValue
                )
            ]
        } else {
            points = historicalPoints
        }

        guard
            let price = latestQuote?.tipoCotizacion ?? points.last?.value,
            !points.isEmpty
        else {
            return nil
        }

        return MarketQuote(
            id: definition.id,
            name: definition.displayName,
            symbol: definition.symbol,
            market: definition.market,
            price: price,
            changePercentage: percentageChange(from: points),
            currencyCode: definition.currencyCode,
            series: points
        )
    }

    private static func mapVariableQuote(
        definition: BCRAMarketQuoteDefinition,
        snapshot: BCRAMonetaryVariableDTO,
        series: [BCRAMonetaryPointDTO]
    ) -> MarketQuote? {
        let historicalPoints = series
            .map {
                MarketPoint(
                    id: "\(definition.id)-\($0.fecha.timeIntervalSince1970)",
                    date: $0.fecha,
                    value: $0.valor
                )
            }
            .sorted { $0.date < $1.date }

        let points: [MarketPoint]

        if historicalPoints.isEmpty, let latestValue = snapshot.ultValorInformado {
            points = [
                MarketPoint(
                    id: "\(definition.id)-snapshot",
                    date: snapshot.ultFechaInformada ?? Date(),
                    value: latestValue
                )
            ]
        } else {
            points = historicalPoints
        }

        guard let price = snapshot.ultValorInformado ?? points.last?.value else {
            return nil
        }

        return MarketQuote(
            id: definition.id,
            name: definition.displayName,
            symbol: definition.symbol,
            market: definition.market,
            price: price,
            changePercentage: percentageChange(from: points),
            currencyCode: definition.currencyCode,
            series: points
        )
    }

    private static func mapIndicator(
        definition: BCRAMarketIndicatorDefinition,
        snapshot: BCRAMonetaryVariableDTO
    ) -> MarketIndicator? {
        guard let value = snapshot.ultValorInformado else {
            return nil
        }

        return MarketIndicator(
            id: definition.id,
            name: definition.displayName,
            value: value,
            unit: definition.unitOverride ?? normalizedUnit(snapshot.unidadExpresion),
            changePercentage: nil
        )
    }

    private static func exchangeCode(for definition: BCRAMarketQuoteDefinition) -> String {
        guard case let .exchangeRate(code) = definition.source else {
            return ""
        }

        return code
    }

    private static func percentageChange(from points: [MarketPoint]) -> Double {
        guard points.count >= 2 else {
            return 0
        }

        let latest = points[points.count - 1].value
        let previous = points[points.count - 2].value

        guard previous != 0 else {
            return 0
        }

        return ((latest - previous) / previous) * 100
    }

    private static func normalizedUnit(_ unit: String) -> String {
        let normalized = unit
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        switch normalized {
        case "En millones de USD":
            return "M USD"
        case "Pesos argentinos por dólar estadounidense":
            return "ARS/USD"
        case "En porcentaje nominal anual":
            return "% TNA"
        case "En millones de pesos":
            return "M ARS"
        default:
            return normalized
        }
    }
}
