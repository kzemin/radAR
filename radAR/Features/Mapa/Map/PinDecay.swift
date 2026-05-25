import Foundation

/// Time-based fade for map pins so the radar reads "what's hot right now": a fresh
/// breaking event is orange and cools to white as it ages, normal events are plain
/// white, and anything past the 24h feed window drops off the map. Pins stay fully
/// opaque — the only time signal is the breaking hue, never alpha, which would just
/// muddy the square against the dark basemap.
enum PinDecay {
    /// Events older than this have left the live feed and are no longer drawn.
    static let window: TimeInterval = 24 * 3600
    /// Time constant of the exponential cool-down. Sized so the change is
    /// perceptible across the window instead of flat-lining within the first hours.
    static let tau: TimeInterval = 8 * 3600

    /// Whether an event of the given `age` (seconds since published) still shows.
    static func isLive(age: TimeInterval) -> Bool {
        age < window
    }

    /// Freshness 0…1 (1 = brand new) driving how far a breaking pin's hue has
    /// cooled from orange toward white.
    static func freshness(age: TimeInterval) -> Double {
        exp(-max(0, age) / tau)
    }
}
