import CoreLocation
import Foundation

struct NewsEvent: Identifiable, Hashable {
    let id: UUID
    let headline: String
    let body: String
    let province: ArgentineProvince
    let coordinate: CLLocationCoordinate2D
    let timestamp: Date
    let category: NewsCategory
    let severity: NewsSeverity
    let sourceID: String?
    let sourceURL: URL?
    let imageURL: URL?

    init(
        id: UUID = UUID(),
        headline: String,
        body: String,
        province: ArgentineProvince,
        coordinate: CLLocationCoordinate2D? = nil,
        timestamp: Date,
        category: NewsCategory,
        severity: NewsSeverity = .normal,
        sourceID: String? = nil,
        sourceURL: URL? = nil,
        imageURL: URL? = nil
    ) {
        self.id = id
        self.headline = headline
        self.body = body
        self.province = province
        self.coordinate = coordinate ?? province.centroid
        self.timestamp = timestamp
        self.category = category
        self.severity = severity
        self.sourceID = sourceID
        self.sourceURL = sourceURL
        self.imageURL = imageURL
    }

    /// National-scope event: no point location, surfaced via the ticker, and
    /// selecting it highlights the whole country rather than a single province.
    var isNational: Bool { province == .nacional }

    /// Short brand label derived from the source URL host — e.g. `Clarin.com`,
    /// `Infobae.com`. Returns nil when there's no usable source URL.
    var sourceLabel: String? {
        guard let host = sourceURL?.host() else { return nil }
        let trimmed = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        guard let first = trimmed.first else { return nil }
        return first.uppercased() + trimmed.dropFirst()
    }

    /// Short brand name (e.g. "Clarín", "La Nación", "TN") for the source row in
    /// the drawer. Falls back to the URL-derived host (`sourceLabel`) when the
    /// id isn't in the catalog, so a newly-added feed still reads as something.
    var sourceName: String? {
        if let id = sourceID, let name = Self.sourceNames[id] { return name }
        return sourceLabel
    }

    /// Catalog of short brand names per source id. The DB `sources` table holds
    /// long-form names with parentheticals ("Olé (deportes)", "Ámbito Financiero",
    /// "Todo Noticias"); these are the punchy display forms for a news card.
    private static let sourceNames: [String: String] = [
        "infobae":   "Infobae",
        "lanacion":  "La Nación",
        "clarin":    "Clarín",
        "pagina12":  "Página/12",
        "ambito":    "Ámbito",
        "tn":        "TN",
        "lavoz":     "La Voz",
        "losandes":  "Los Andes",
        "rionegro":  "Río Negro",
        "ole":       "Olé",
    ]

    static func == (lhs: NewsEvent, rhs: NewsEvent) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
