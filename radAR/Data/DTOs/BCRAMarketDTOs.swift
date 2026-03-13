import Foundation

struct BCRAMonetaryVariableDTO: Decodable {
    let idVariable: Int
    let descripcion: String
    let categoria: String
    let tipoSerie: String
    let periodicidad: String
    let unidadExpresion: String
    let moneda: String
    let primerFechaInformada: Date?
    let ultFechaInformada: Date?
    let ultValorInformado: Double?
}

struct BCRAMonetarySeriesDTO: Decodable {
    let idVariable: Int
    let detalle: [BCRAMonetaryPointDTO]
}

struct BCRAMonetaryPointDTO: Decodable {
    let fecha: Date
    let valor: Double
}

struct BCRAExchangeRatesSnapshotDTO: Decodable {
    let fecha: Date
    let detalle: [BCRAExchangeRateQuoteDTO]
}

struct BCRAExchangeRateHistoryEntryDTO: Decodable {
    let fecha: Date
    let detalle: [BCRAExchangeRateQuoteDTO]
}

struct BCRAExchangeRateQuoteDTO: Decodable {
    let codigoMoneda: String
    let descripcion: String
    let tipoPase: Double?
    let tipoCotizacion: Double?
}
