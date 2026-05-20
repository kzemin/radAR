import CoreLocation
import Foundation
import Observation

@MainActor
@Observable
final class MapaStore {
    private(set) var events: [NewsEvent]
    private(set) var provinces: [ProvinceShape]
    private(set) var argentinaExtras: [BackdropShape]
    private(set) var worldCountries: [BackdropShape]

    var selectedEventID: NewsEvent.ID?
    var calloutEventID: NewsEvent.ID?
    var cameraTargetProvince: ArgentineProvince?
    var cameraTargetCoordinate: CLLocationCoordinate2D?
    var cameraNonce: Int
    var isDrawerExpanded: Bool

    init(
        events: [NewsEvent] = MockNewsData.seed(),
        provinces: [ProvinceShape] = ProvinceGeometryLoader.load(),
        argentinaExtras: [BackdropShape] = ExtrasGeometryLoader.load(),
        worldCountries: [BackdropShape] = WorldGeometryLoader.load()
    ) {
        self.events = events.sorted { $0.timestamp > $1.timestamp }
        self.provinces = provinces
        self.argentinaExtras = argentinaExtras
        self.worldCountries = worldCountries
        self.selectedEventID = nil
        self.calloutEventID = nil
        self.cameraTargetProvince = nil
        self.cameraTargetCoordinate = nil
        self.cameraNonce = 0
        self.isDrawerExpanded = false
    }

    var selectedEvent: NewsEvent? {
        guard let id = selectedEventID else { return nil }
        return events.first(where: { $0.id == id })
    }

    var calloutEvent: NewsEvent? {
        guard let id = calloutEventID else { return nil }
        return events.first(where: { $0.id == id })
    }

    var activeProvinces: Set<ArgentineProvince> {
        Set(events.map(\.province))
    }

    /// Selects an event from anywhere (map pin or drawer list): flies the camera
    /// to it and opens the floating callout with its detail.
    func select(event: NewsEvent) {
        selectedEventID = event.id
        calloutEventID = event.id
        cameraTargetProvince = event.province
        cameraTargetCoordinate = event.coordinate
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
