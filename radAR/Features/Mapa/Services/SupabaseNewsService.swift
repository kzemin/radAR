import CoreLocation
import Foundation

/// radAR Supabase connection. The publishable key is client-safe (RLS is the
/// security boundary), so it ships in the app.
enum SupabaseConfig {
    static let url = URL(string: "https://oqgffwkehcmedwvgceku.supabase.co")!
    static let publishableKey = "sb_publishable_IONK6dy1fWC5D6m1hECCvg_lzDINlDi"
}

/// Reads live news from Supabase via PostgREST. Conforms to `NewsService`, so it
/// drops in behind the seam the app already uses — no store or UI changes.
struct SupabaseNewsService: NewsService {
    var baseURL: URL = SupabaseConfig.url
    var apiKey: String = SupabaseConfig.publishableKey
    var session: URLSession = .shared

    func fetchEvents() async throws -> [NewsEvent] {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("rest/v1/news_events"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "order", value: "occurred_at.desc"),
            URLQueryItem(name: "limit", value: "200"),
        ]

        var request = URLRequest(url: components.url!)
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        // National-scope rows have no province and are handled separately later, so
        // `compactMap` drops anything that can't become a provincial pin for now.
        return try decoder.decode([NewsEventDTO].self, from: data).compactMap { $0.toNewsEvent() }
    }
}

private struct NewsEventDTO: Decodable {
    let id: String
    let headline: String
    let body: String
    let province: String?
    let lat: Double?
    let lon: Double?
    let occurredAt: String
    let category: String
    let severity: String
    let sourceUrl: String?

    func toNewsEvent() -> NewsEvent? {
        guard
            let uuid = UUID(uuidString: id),
            let province = province.flatMap(ArgentineProvince.init(rawValue:)),
            let timestamp = Self.parseDate(occurredAt)
        else { return nil }

        let coordinate: CLLocationCoordinate2D? = {
            guard let lat, let lon else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }()

        return NewsEvent(
            id: uuid,
            headline: headline,
            body: body,
            province: province,
            coordinate: coordinate,
            timestamp: timestamp,
            category: NewsCategory(rawValue: category) ?? .otro,
            severity: NewsSeverity(rawValue: severity) ?? .normal,
            sourceURL: sourceUrl.flatMap(URL.init(string:))
        )
    }

    private static func parseDate(_ value: String) -> Date? {
        let withFractional = ISO8601DateFormatter()
        withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = withFractional.date(from: value) { return date }
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return plain.date(from: value)
    }
}
