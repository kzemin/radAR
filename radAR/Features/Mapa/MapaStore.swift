import CoreLocation
import Foundation
import Observation

@MainActor
@Observable
final class MapaStore {
    enum LoadState: Equatable {
        case loading
        case loaded
        case failed(String)
    }

    private(set) var events: [NewsEvent] = []
    private(set) var quotes: [MarketQuote] = []
    private(set) var loadState: LoadState = .loading
    private(set) var provinces: [ProvinceShape]
    private(set) var argentinaExtras: [BackdropShape]
    private(set) var worldCountries: [BackdropShape]

    var selectedEventID: NewsEvent.ID?
    var calloutEventID: NewsEvent.ID?
    var cameraTargetProvince: ArgentineProvince?
    var cameraTargetCoordinate: CLLocationCoordinate2D?
    /// Optional zoom override applied when `cameraTargetCoordinate` is nil — lets a
    /// national selection pull back further than the default country frame.
    var cameraTargetZoom: Double?
    var cameraNonce: Int = 0
    var isDrawerExpanded: Bool = false

    private let newsService: NewsService
    private let marketService: MarketService
    private let newsCache: NewsCache

    init(
        newsService: NewsService = MockNewsService(),
        marketService: MarketService = DolarApiMarketService(),
        newsCache: NewsCache = .shared,
        provinces: [ProvinceShape] = ProvinceGeometryLoader.load(),
        argentinaExtras: [BackdropShape] = ExtrasGeometryLoader.load(),
        worldCountries: [BackdropShape] = WorldGeometryLoader.load()
    ) {
        self.newsService = newsService
        self.marketService = marketService
        self.newsCache = newsCache
        self.provinces = provinces
        self.argentinaExtras = argentinaExtras
        self.worldCountries = worldCountries

        // Hydrate from disk synchronously so the drawer + map paint before the
        // first network round-trip. The live `load()` runs right after and
        // overwrites with fresh data — users never see a loading spinner unless
        // it's a brand-new install with nothing cached.
        let cached = newsCache.load().sorted { $0.timestamp > $1.timestamp }
        if !cached.isEmpty {
            self.events = cached
            self.loadState = .loaded
        }
    }

    /// Event a push tap wants to open, held until the feed has it loaded.
    private var pendingPushEventID: UUID?

    /// Loads the feed through `NewsService`. Call from the view's `.task`; safe to
    /// re-run. Silently keeps cached events on failure so the map doesn't blank
    /// out on a transient network blip.
    func load() async {
        let hadEvents = !events.isEmpty
        if !hadEvents { loadState = .loading }
        do {
            let fetched = try await newsService.fetchEvents()
            events = fetched.sorted { $0.timestamp > $1.timestamp }
            loadState = .loaded
            newsCache.save(events)
            resolvePendingPush()
        } catch {
            // Only surface the error if we have nothing else to show — otherwise
            // the user keeps reading the cached list and never knows it failed.
            if !hadEvents {
                loadState = .failed("No se pudieron cargar las noticias.")
            }
        }
    }

    /// Open an event from a tapped push. If it isn't loaded yet (cold launch
    /// straight from the notification), remember it and resolve after `load()`.
    func openFromPush(eventID: UUID) {
        if let event = events.first(where: { $0.id == eventID }) {
            select(event: event)
            pendingPushEventID = nil
        } else {
            pendingPushEventID = eventID
        }
    }

    private func resolvePendingPush() {
        guard let id = pendingPushEventID,
              let event = events.first(where: { $0.id == id }) else { return }
        select(event: event)
        pendingPushEventID = nil
    }

    /// Best-effort refresh of the market strip. Failures leave the previous values
    /// in place so the ticker doesn't blink to empty on a transient network blip.
    func loadMarket() async {
        let fetched = await marketService.fetchQuotes()
        guard !fetched.isEmpty else { return }
        quotes = fetched
    }

    var selectedEvent: NewsEvent? {
        guard let id = selectedEventID else { return nil }
        return events.first(where: { $0.id == id })
    }

    var calloutEvent: NewsEvent? {
        guard let id = calloutEventID else { return nil }
        return events.first(where: { $0.id == id })
    }

    /// Province pins / drawer list. National events live in the ticker instead.
    var provincialEvents: [NewsEvent] {
        events.filter { !$0.isNational }
    }

    /// Whole-country events, surfaced through the ticker (breaking first).
    var nationalEvents: [NewsEvent] {
        events.filter(\.isNational)
    }

    var activeProvinces: Set<ArgentineProvince> {
        Set(provincialEvents.map(\.province))
    }

    /// Selects an event from anywhere (map pin, drawer list, or ticker): flies the
    /// camera to it and opens the floating callout with its detail.
    func select(event: NewsEvent) {
        selectedEventID = event.id
        calloutEventID = event.id
        // National events have no point location — pull back to the country
        // overview (nil target) instead of flying to a centroid.
        cameraTargetProvince = event.isNational ? nil : event.province
        cameraTargetCoordinate = event.isNational ? nil : event.coordinate
        cameraTargetZoom = event.isNational ? 0.75 : nil
        cameraNonce &+= 1
    }

    func dismissCallout() {
        calloutEventID = nil
    }

    /// Tap-outside on the map: clear callout + pin selection but leave the
    /// camera where the user left it.
    func deselect() {
        selectedEventID = nil
        calloutEventID = nil
    }

    func clearSelection() {
        selectedEventID = nil
        calloutEventID = nil
        cameraTargetProvince = nil
        cameraTargetCoordinate = nil
        cameraTargetZoom = nil
        cameraNonce &+= 1
    }

    func toggleDrawer() {
        isDrawerExpanded.toggle()
    }
}
