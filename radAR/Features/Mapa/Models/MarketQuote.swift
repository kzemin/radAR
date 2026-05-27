import Foundation

/// A single live market value rendered in the ticker. Keeps `value` as a
/// pre-formatted display string so callers don't need to know which locale
/// or unit applies to each kind (pesos for dollars, "pb" for riesgo país).
struct MarketQuote: Identifiable, Hashable {
    let kind: Kind
    let value: String

    var id: Kind { kind }
    var label: String { kind.label }

    enum Kind: String, CaseIterable, Hashable {
        case dolarOficial
        case dolarBlue
        case dolarMep
        case dolarCcl
        case dolarMayorista
        case riesgoPais

        var label: String {
            switch self {
            case .dolarOficial: "Dólar oficial"
            case .dolarBlue: "Dólar blue"
            case .dolarMep: "MEP"
            case .dolarCcl: "CCL"
            case .dolarMayorista: "Mayorista"
            case .riesgoPais: "Riesgo país"
            }
        }
    }
}
