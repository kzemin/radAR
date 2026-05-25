import Foundation

/// Source of news events for the map. The app depends on this protocol — not on a
/// concrete feed — so the data source can move from bundled mock to the live
/// Supabase backend (see `NETWORKING_ROADMAP.md`) without touching the UI or store.
protocol NewsService {
    func fetchEvents() async throws -> [NewsEvent]
}

/// Serves the bundled mock feed. Keeps the app running end-to-end while the live
/// ingestion pipeline is built behind the same protocol.
struct MockNewsService: NewsService {
    func fetchEvents() async throws -> [NewsEvent] {
        MockNewsData.seed()
    }
}
