import Foundation
import Observation

/// Carries a tapped push notification's target event from the app delegate to
/// the map. Lives outside the SwiftUI view tree because a notification tap can
/// fire before any view exists (cold launch straight from the notification);
/// `MapaView` reads `pendingEventID` once the feed is loaded and selects it.
@MainActor
@Observable
final class PushInbox {
    static let shared = PushInbox()
    var pendingEventID: UUID?
    private init() {}
}
