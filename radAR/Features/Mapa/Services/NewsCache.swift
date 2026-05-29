import CoreLocation
import Foundation

/// Persistent last-known list of news events, backed by UserDefaults. Used to
/// paint the drawer + map instantly on cold launch instead of waiting on the
/// network, and to keep showing something if the live fetch fails on a flaky
/// reviewer connection. The live `fetchEvents()` always runs after hydration
/// and silently overwrites what was loaded from cache.
///
/// `NewsEvent` itself isn't Codable (CLLocationCoordinate2D doesn't conform), so
/// we serialize through a flat `Cached` DTO and convert back on read.
final class NewsCache {
    static let shared = NewsCache()

    private let storageKey = "radar.news.cache.v1"
    /// Cached events older than this are dropped on hydration — keeps a months-old
    /// cache from briefly painting ancient news during the first live-fetch beat.
    private let maxAge: TimeInterval = 7 * 86_400
    private let lock = NSLock()
    private let storage: UserDefaults

    init(storage: UserDefaults = .standard) {
        self.storage = storage
    }

    func save(_ events: [NewsEvent]) {
        lock.lock()
        defer { lock.unlock() }
        let cached = events.map(Cached.init(from:))
        if let data = try? JSONEncoder().encode(cached) {
            storage.set(data, forKey: storageKey)
        }
    }

    func load() -> [NewsEvent] {
        lock.lock()
        defer { lock.unlock() }
        guard let data = storage.data(forKey: storageKey),
              let cached = try? JSONDecoder().decode([Cached].self, from: data)
        else { return [] }
        let now = Date()
        return cached
            .filter { now.timeIntervalSince($0.timestamp) < maxAge }
            .map { $0.toNewsEvent() }
    }

    private struct Cached: Codable {
        let id: UUID
        let headline: String
        let body: String
        let provinceCode: String
        let lat: Double
        let lon: Double
        let timestamp: Date
        let categoryCode: String
        let severityCode: String
        let sourceID: String?
        let sourceURL: URL?
        let imageURL: URL?

        init(from event: NewsEvent) {
            self.id = event.id
            self.headline = event.headline
            self.body = event.body
            self.provinceCode = event.province.rawValue
            self.lat = event.coordinate.latitude
            self.lon = event.coordinate.longitude
            self.timestamp = event.timestamp
            self.categoryCode = event.category.rawValue
            self.severityCode = event.severity.rawValue
            self.sourceID = event.sourceID
            self.sourceURL = event.sourceURL
            self.imageURL = event.imageURL
        }

        func toNewsEvent() -> NewsEvent {
            NewsEvent(
                id: id,
                headline: headline,
                body: body,
                province: ArgentineProvince(rawValue: provinceCode) ?? .nacional,
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                timestamp: timestamp,
                category: NewsCategory(rawValue: categoryCode) ?? .otro,
                severity: NewsSeverity(rawValue: severityCode) ?? .normal,
                sourceID: sourceID,
                sourceURL: sourceURL,
                imageURL: imageURL
            )
        }
    }
}
