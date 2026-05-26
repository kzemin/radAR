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

    static func == (lhs: NewsEvent, rhs: NewsEvent) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
