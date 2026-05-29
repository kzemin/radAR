import Foundation

/// A single live market value rendered in the ticker. Keeps `value` as a
/// pre-formatted display string so callers don't need to know which locale
/// or unit applies to each kind (pesos for dollars, "pb" for riesgo país).
struct MarketQuote: Identifiable, Hashable {
    let kind: Kind
    let value: String
    /// Daily-ish movement, pre-formatted as "+X,YY%" or "-X,YY%". Nil when no
    /// source data is available yet (fresh install, first refresh, or a stat
    /// item that doesn't carry a change column).
    let change: String?

    init(kind: Kind, value: String, change: String? = nil) {
        self.kind = kind
        self.value = value
        self.change = change
    }

    var id: Kind { kind }
    var label: String { kind.label }

    enum Kind: String, CaseIterable, Hashable {
        case dolarOficial
        case dolarBlue
        case dolarCcl
        case dolarUsdt
        case merval
        case spx
        case btc
        case riesgoPais
        case inflacion
        case bcraReservas
        case soja
        case petroleo

        var label: String {
            switch self {
            case .dolarOficial: "Dólar oficial"
            case .dolarBlue: "Dólar blue"
            case .dolarCcl: "CCL"
            case .dolarUsdt: "USDT"
            case .merval: "Merval"
            case .spx: "S&P 500"
            case .btc: "BTC"
            case .riesgoPais: "Riesgo país"
            case .inflacion: "Inflación"
            case .bcraReservas: "BCRA reservas"
            case .soja: "Soja"
            case .petroleo: "Petróleo"
            }
        }
    }
}
