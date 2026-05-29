import Foundation

/// Persistent last-known-value store for market quotes, backed by UserDefaults.
///
/// Two roles in one file:
///  1. **Fallback cache** — if every live endpoint fails, `quote(for:)` returns
///     the last stored display value (or the bundled seed on a fresh install).
///  2. **Daily-change anchor** — for quotes whose source doesn't expose a
///     `variation` field (e.g. dolarapi for dollars), we keep a numeric baseline
///     and let callers compute deltas against it. The anchor stays put for 6h
///     so the change column reads as "daily-ish" rather than 5-minute noise.
///
/// Thread-safe via `NSLock` — `MarketService.fetchQuotes()` writes from many
/// concurrent async tasks.
final class QuoteCache {
    static let shared = QuoteCache()

    private let storageKey = "radar.market.quote.cache.v2"
    /// Cached display values older than this aren't returned — better to drop
    /// a quote than show a year-old number.
    private let maxAge: TimeInterval = 60 * 86_400
    private let lock = NSLock()
    private let storage: UserDefaults

    /// ART calendar day (UTC-3, no DST) used to roll over the daily-change
    /// anchor at Argentine midnight. Matches BYMA / Stooq / Yahoo's "today
    /// vs prev close" convention so every quote's % reads on the same clock.
    private static let artDayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = TimeZone(secondsFromGMT: -3 * 3600)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    init(storage: UserDefaults = .standard) {
        self.storage = storage
    }

    /// Persist a successful live fetch. `numeric` (where available) is used to
    /// maintain the daily-change anchor — pass nil for stat-only quotes.
    func save(_ quote: MarketQuote, numeric: Double? = nil) {
        lock.lock()
        defer { lock.unlock() }
        var dict = load()
        let existing = dict[quote.kind.rawValue]
        let now = Date()

        // Anchor rolls over once per ART calendar day. Within the same day we
        // keep the anchor pinned so the delta reads as "today vs yesterday's
        // close"; on the first save after midnight ART we promote the previous
        // current (or the bundled seed on a fresh install) as the new baseline.
        let today = Self.artDayFormatter.string(from: now)
        let anchorDay = existing?.anchorAt.map { Self.artDayFormatter.string(from: $0) }
        let newAnchorNumeric: Double?
        let newAnchorAt: Date?
        if anchorDay == today {
            newAnchorNumeric = existing?.anchorNumeric
            newAnchorAt = existing?.anchorAt
        } else {
            newAnchorNumeric = existing?.numeric ?? Self.seedNumeric[quote.kind]
            newAnchorAt = now
        }

        dict[quote.kind.rawValue] = Stored(
            value: quote.value,
            numeric: numeric,
            savedAt: now,
            anchorNumeric: newAnchorNumeric,
            anchorAt: newAnchorAt
        )
        try? persist(dict)
    }

    /// Return the last cached display value for `kind`, falling back to the
    /// bundled seed so a fresh install never shows an empty ticker.
    func quote(for kind: MarketQuote.Kind) -> MarketQuote? {
        lock.lock()
        defer { lock.unlock() }
        if let stored = load()[kind.rawValue],
           Date().timeIntervalSince(stored.savedAt) < maxAge {
            return MarketQuote(kind: kind, value: stored.value)
        }
        if let bundled = Self.seed[kind] {
            return MarketQuote(kind: kind, value: bundled)
        }
        return nil
    }

    /// The "yesterday" numeric value used to compute the change column.
    /// Falls back to the bundled seed so deltas appear from the first live fetch.
    func anchor(for kind: MarketQuote.Kind) -> Double? {
        lock.lock()
        defer { lock.unlock() }
        return load()[kind.rawValue]?.anchorNumeric ?? Self.seedNumeric[kind]
    }

    private func load() -> [String: Stored] {
        guard let data = storage.data(forKey: storageKey),
              let dict = try? JSONDecoder().decode([String: Stored].self, from: data)
        else { return [:] }
        return dict
    }

    private func persist(_ dict: [String: Stored]) throws {
        let data = try JSONEncoder().encode(dict)
        storage.set(data, forKey: storageKey)
    }

    private struct Stored: Codable {
        let value: String
        let numeric: Double?
        let savedAt: Date
        let anchorNumeric: Double?
        let anchorAt: Date?
    }

    /// Frozen real display values from build time — used only when there's
    /// nothing cached yet (fresh install + every live endpoint failing).
    /// Re-snap before each App Store release to keep them plausible.
    private static let seed: [MarketQuote.Kind: String] = [
        .dolarOficial:  "C: $1.380,00 | V: $1.430,00",
        .dolarBlue:     "C: $1.420,00 | V: $1.440,00",
        .dolarCcl:      "$1.484,80",
        .dolarUsdt:     "C: $1.486,20 | V: $1.486,30",
        .merval:        "2.997.833",
        .spx:           "7.520,36",
        .btc:           "US$72.947",
        .riesgoPais:    "508 pb",
        .inflacion:     "2,6%",
        .bcraReservas:  "US$46,8B",
        .soja:          "US$437,16",
        .petroleo:      "US$92,25",
    ]

    /// Numeric form of the seed for the daily-change anchor. Dollars use their
    /// `venta` price (matches the rest of the change-tracking math). Stat-only
    /// items (riesgo país, inflación, reservas) don't need an anchor.
    private static let seedNumeric: [MarketQuote.Kind: Double] = [
        .dolarOficial:  1430.0,
        .dolarBlue:     1440.0,
        .dolarCcl:      1484.8,
        .dolarUsdt:     1486.3,
        .merval:        2_997_833.0,
        .spx:           7520.36,
        .btc:           72_946.6,
        .soja:          437.16,
        .petroleo:      92.25,
    ]
}
