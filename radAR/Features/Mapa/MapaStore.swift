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
    var cameraNonce: Int = 0
    var isDrawerExpanded: Bool = false

    private let newsService: NewsService
    private let marketService: MarketService

    init(
        newsService: NewsService = MockNewsService(),
        marketService: MarketService = DolarApiMarketService(),
        provinces: [ProvinceShape] = ProvinceGeometryLoader.load(),
        argentinaExtras: [BackdropShape] = ExtrasGeometryLoader.load(),
        worldCountries: [BackdropShape] = WorldGeometryLoader.load()
    ) {
        self.newsService = newsService
        self.marketService = marketService
        self.provinces = provinces
        self.argentinaExtras = argentinaExtras
        self.worldCountries = worldCountries
    }

    /// Loads the feed through `NewsService`. Call from the view's `.task`; safe to
    /// re-run (e.g. pull-to-refresh later).
    func load() async {
        loadState = .loading
        do {
            let fetched = try await newsService.fetchEvents()
            events = fetched.sorted { $0.timestamp > $1.timestamp }
            loadState = .loaded
        } catch {
            loadState = .failed("No se pudieron cargar las noticias.")
        }
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
        cameraNonce &+= 1
    }

    func toggleDrawer() {
        isDrawerExpanded.toggle()
    }
}
