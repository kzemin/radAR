import Foundation

/// Recency "heat" for map pins: a freshly-occurred event glows orange (accent)
/// and cools to the normal white pin tone as it ages, so the map reads "what's
/// hot right now". Breaking events stay hot longer. Visibility itself is governed
/// by the server's `expires_at` window — PinDecay only drives the hue.
enum PinDecay {
    /// Cool-down constant for routine events — orange fades to white over a few hours.
    static let normalTau: TimeInterval = 8 * 3600
    /// Breaking events stay hot ~3× longer before cooling.
    static let breakingTau: TimeInterval = 24 * 3600

    /// Freshness 0…1 (1 = brand new) driving how far a pin's hue has cooled from
    /// orange toward white. Larger `tau` = slower cool-down.
    static func freshness(age: TimeInterval, tau: TimeInterval) -> Double {
        exp(-max(0, age) / tau)
    }
}
