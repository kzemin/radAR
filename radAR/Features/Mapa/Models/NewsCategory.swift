import Foundation

enum NewsCategory: String, Codable, CaseIterable, Hashable, Identifiable {
    case politica
    case economia
    case seguridad
    case social
    case deportes
    case otro

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .politica: "Política"
        case .economia: "Economía"
        case .seguridad: "Seguridad"
        case .social: "Social"
        case .deportes: "Deportes"
        case .otro: "Otro"
        }
    }

    var code: String {
        switch self {
        case .politica: "POL"
        case .economia: "ECO"
        case .seguridad: "SEG"
        case .social: "SOC"
        case .deportes: "DEP"
        case .otro: "OTR"
        }
    }

    /// SF Symbol used as a placeholder thumbnail until real imagery is wired in.
    var symbolName: String {
        switch self {
        case .politica: "building.columns.fill"
        case .economia: "chart.line.uptrend.xyaxis"
        case .seguridad: "shield.lefthalf.filled"
        case .social: "person.3.fill"
        case .deportes: "sportscourt.fill"
        case .otro: "newspaper.fill"
        }
    }
}

enum NewsSeverity: String, Codable, Hashable {
    case normal
    case breaking
}
