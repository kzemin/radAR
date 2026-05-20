import Foundation

enum RadarFormatters {
    private static let locale = Locale(identifier: "es_AR")
    private static let posixLocale = Locale(identifier: "en_US_POSIX")
    private static let argentinaTimeZone = TimeZone(identifier: "America/Argentina/Buenos_Aires") ?? .current
    private static let utcTimeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
    private static let shortTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = posixLocale
        formatter.timeZone = argentinaTimeZone
        formatter.dateFormat = "h:mma"
        return formatter
    }()

    private static let timestampDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = posixLocale
        formatter.timeZone = argentinaTimeZone
        formatter.dateFormat = "dd-MMM"
        return formatter
    }()

    static func currency(_ value: Double?, code: String = "ARS") -> String {
        guard let value else {
            return "Sin dato"
        }

        return compactSymbols(
            value.formatted(
            .currency(code: code)
                .locale(locale)
                .presentation(.narrow)
                .precision(.fractionLength(0...2))
        )
        )
    }

    static func rate(_ value: Double?) -> String {
        guard let value else {
            return "Sin dato"
        }

        return value.formatted(
            .number
                .locale(locale)
                .precision(.fractionLength(1...2))
        ) + "%"
    }

    static func compact(_ value: Double?) -> String {
        guard let value else {
            return "Sin dato"
        }

        return value.formatted(
            .number
                .locale(locale)
                .notation(.compactName)
                .precision(.fractionLength(1))
        )
    }

    static func number(_ value: Double?) -> String {
        guard let value else {
            return "Sin dato"
        }

        return value.formatted(
            .number
                .locale(locale)
                .precision(.fractionLength(0...2))
        )
    }

    static func signedRate(_ value: Double?) -> String {
        guard let value else {
            return "Sin dato"
        }

        let formatted = value.formatted(
            .number
                .locale(locale)
                .precision(.fractionLength(1...2))
        )

        return value >= 0 ? "+\(formatted)%" : "\(formatted)%"
    }

    static func shortDate(_ date: Date) -> String {
        date.formatted(
            .dateTime
                .day(.twoDigits)
                .month(.abbreviated)
                .locale(locale)
        )
    }

    /// Compact relative age in Spanish ("recién", "hace 12 min", "hace 20h", "hace 2d").
    /// Tuned for a feed that refreshes within ~24h.
    static func relativeShort(_ date: Date, now: Date = Date()) -> String {
        let seconds = max(0, now.timeIntervalSince(date))
        if seconds < 60 {
            return "recién"
        }
        let minutes = Int(seconds / 60)
        if minutes < 60 {
            return "hace \(minutes) min"
        }
        let hours = Int(seconds / 3600)
        if hours < 24 {
            return "hace \(hours)h"
        }
        let days = Int(seconds / 86_400)
        return "hace \(days)d"
    }

    static func timestamp(_ date: Date) -> String {
        if isDateOnlySource(date) {
            return shortDate(date).uppercased()
        }

        return "\(timestampDateFormatter.string(from: date).uppercased()), \(shortTime(date))"
    }

    static func shortTime(_ date: Date) -> String {
        if isDateOnlySource(date) {
            return shortDate(date).uppercased()
        }

        return shortTimeFormatter
            .string(from: date)
            .replacingOccurrences(of: "AM", with: "A.M.")
            .replacingOccurrences(of: "PM", with: "P.M.")
    }

    private static func compactSymbols(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\u{00A0}", with: "")
            .replacingOccurrences(of: " ", with: "")
    }

    private static func isDateOnlySource(_ date: Date) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = utcTimeZone

        let components = calendar.dateComponents([.hour, .minute, .second], from: date)
        return components.hour == 0 && components.minute == 0 && components.second == 0
    }
}
