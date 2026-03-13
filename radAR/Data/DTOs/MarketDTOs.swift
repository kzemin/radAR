import Foundation

struct MarketOverviewDTO: Decodable {
    let quotes: [MarketQuoteDTO]
    let indicators: [MarketIndicatorDTO]
}

struct MarketQuoteDTO: Decodable {
    let id: String
    let nombre: String
    let simbolo: String
    let mercado: String
    let precio: Double
    let variacion: Double
    let moneda: String
}

struct MarketIndicatorDTO: Decodable {
    let id: String
    let nombre: String
    let valor: Double
    let unidad: String
    let variacion: Double?
}

struct MarketPointDTO: Decodable {
    let fecha: Date
    let valor: Double
}

enum MarketFixtures {
    static let overview = MarketOverviewDTO(
        quotes: [
            .init(id: "usd_oficial", nombre: "Dólar oficial referencia", simbolo: "USD", mercado: "FX", precio: 1_078, variacion: 0.6, moneda: "ARS"),
            .init(id: "usd_mayorista", nombre: "Tipo de cambio mayorista", simbolo: "USD MAYORISTA", mercado: "FX", precio: 1_062.5, variacion: 0.4, moneda: "ARS"),
            .init(id: "usd_minorista", nombre: "Tipo de cambio minorista", simbolo: "USD MINORISTA", mercado: "FX", precio: 1_094.2, variacion: 0.5, moneda: "ARS"),
            .init(id: "usd_mep", nombre: "Dólar MEP", simbolo: "USD MEP", mercado: "Bonos", precio: 1_125.4, variacion: -0.3, moneda: "ARS"),
            .init(id: "usd_ccl", nombre: "Contado con liquidación", simbolo: "USD CCL", mercado: "Bonos", precio: 1_161.7, variacion: 0.2, moneda: "ARS"),
            .init(id: "badlar", nombre: "BADLAR bancos privados", simbolo: "BADLAR", mercado: "Tasas", precio: 32.8, variacion: -1.1, moneda: "ARS"),
            .init(id: "tm20", nombre: "TM20 bancos privados", simbolo: "TM20", mercado: "Tasas", precio: 35.6, variacion: 0.5, moneda: "ARS")
        ],
        indicators: [
            .init(id: "inflacion_esperada", nombre: "Inflación esperada", valor: 2.7, unidad: "% m/m", variacion: -0.2),
            .init(id: "riesgo_pais", nombre: "Riesgo país", valor: 718, unidad: "pbs", variacion: 1.8),
            .init(id: "reservas", nombre: "Reservas brutas", valor: 28_400, unidad: "M USD", variacion: 0.9),
            .init(id: "base_monetaria", nombre: "Base monetaria", valor: 19_800, unidad: "ARS bn", variacion: 0.5),
            .init(id: "tcrm", nombre: "Tipo de cambio real multilateral", valor: 91.4, unidad: "índice", variacion: -0.6),
            .init(id: "depositos_privados", nombre: "Depósitos privados en pesos", valor: 50_200, unidad: "ARS bn", variacion: 1.2)
        ]
    )

    static func series(for quoteID: String) -> [MarketPointDTO] {
        let totalPoints = 380
        let baseValue: Double
        let drift: Double
        let amplitude: Double

        switch quoteID {
        case "usd_oficial":
            baseValue = 945
            drift = 0.36
            amplitude = 5.8
        case "usd_mayorista":
            baseValue = 930
            drift = 0.35
            amplitude = 4.4
        case "usd_minorista":
            baseValue = 968
            drift = 0.36
            amplitude = 4.9
        case "usd_mep":
            baseValue = 1_012
            drift = 0.31
            amplitude = 9.4
        case "usd_ccl":
            baseValue = 1_041
            drift = 0.34
            amplitude = 10.8
        case "tm20":
            baseValue = 37.5
            drift = -0.01
            amplitude = 0.8
        default:
            baseValue = 39
            drift = -0.02
            amplitude = 0.9
        }

        return (0..<totalPoints).map { index in
            let date = Calendar.current.date(byAdding: .day, value: -(totalPoints - index), to: .now) ?? .now
            let seasonal = sin(Double(index) / 13) * amplitude
            let microTrend = cos(Double(index) / 28) * (amplitude * 0.35)
            return MarketPointDTO(
                fecha: date,
                valor: max(0.1, baseValue + (Double(index) * drift) + seasonal + microTrend)
            )
        }
    }
}
