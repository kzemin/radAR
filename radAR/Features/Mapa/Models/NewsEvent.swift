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

    init(
        id: UUID = UUID(),
        headline: String,
        body: String,
        province: ArgentineProvince,
        coordinate: CLLocationCoordinate2D? = nil,
        timestamp: Date,
        category: NewsCategory,
        severity: NewsSeverity = .normal,
        sourceURL: URL? = nil
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
    }

    static func == (lhs: NewsEvent, rhs: NewsEvent) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
