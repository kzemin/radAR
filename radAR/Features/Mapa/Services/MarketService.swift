import Foundation

/// Source of live market quotes for the ticker. A best-effort fetch — partial
/// failures return whatever loaded so the ticker still has something to show.
protocol MarketService {
    func fetchQuotes() async -> [MarketQuote]
}

/// Pulls dollar quotes from dolarapi.com (free, no key) and riesgo país from
/// argentinadatos.com. Both endpoints are HTTPS, public, and rate-limit friendly.
struct DolarApiMarketService: MarketService {
    var session: URLSession = .shared

    func fetchQuotes() async -> [MarketQuote] {
        async let dollars = fetchDollars()
        async let risk = fetchRiesgoPais()
        var result = await dollars
        if let r = await risk { result.append(r) }
        return result
    }

    private func fetchDollars() async -> [MarketQuote] {
        guard let url = URL(string: "https://dolarapi.com/v1/dolares") else { return [] }
        do {
            let (data, _) = try await session.data(from: url)
            let rows = try JSONDecoder().decode([DolarRow].self, from: data)
            return rows.compactMap { row in
                guard let kind = kind(forCasa: row.casa), let venta = row.venta else { return nil }
                return MarketQuote(kind: kind, value: Self.peso.format(venta))
            }
            // Display in the canonical order, not the API's order.
            .sorted { lhs, rhs in
                Self.dollarOrder.firstIndex(of: lhs.kind) ?? .max
                    < Self.dollarOrder.firstIndex(of: rhs.kind) ?? .max
            }
        } catch {
            return []
        }
    }

    private func fetchRiesgoPais() async -> MarketQuote? {
        guard let url = URL(string: "https://api.argentinadatos.com/v1/finanzas/indices/riesgo-pais") else { return nil }
        do {
            let (data, _) = try await session.data(from: url)
            let rows = try JSONDecoder().decode([RiskRow].self, from: data)
            guard let latest = rows.max(by: { $0.fecha < $1.fecha }) else { return nil }
            return MarketQuote(kind: .riesgoPais, value: "\(Int(latest.valor.rounded())) pb")
        } catch {
            return nil
        }
    }

    private func kind(forCasa casa: String) -> MarketQuote.Kind? {
        switch casa {
        case "oficial": .dolarOficial
        case "blue": .dolarBlue
        case "bolsa": .dolarMep
        case "contadoconliqui": .dolarCcl
        case "mayorista": .dolarMayorista
        default: nil
        }
    }

    private static let dollarOrder: [MarketQuote.Kind] = [
        .dolarOficial, .dolarBlue, .dolarMep, .dolarCcl, .dolarMayorista
    ]

    private static let peso = PesoFormatter()

    private struct PesoFormatter {
        let nf: NumberFormatter = {
            let f = NumberFormatter()
            f.locale = Locale(identifier: "es_AR")
            f.numberStyle = .currency
            f.currencyCode = "ARS"
            f.currencySymbol = "$"
            f.minimumFractionDigits = 2
            f.maximumFractionDigits = 2
            return f
        }()
        func format(_ value: Double) -> String {
            nf.string(from: NSNumber(value: value)) ?? String(value)
        }
    }

    private struct DolarRow: Decodable {
        let casa: String
        let venta: Double?
    }

    private struct RiskRow: Decodable {
        let fecha: String
        let valor: Double
    }
}
