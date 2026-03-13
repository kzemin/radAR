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

    static func metric(_ metric: FinancialMetric, compact: Bool = false) -> String {
        switch metric.format {
        case let .currency(code):
            return currency(metric.value, code: code)
        case .percentage:
            return rate(metric.value)
        case let .number(unit):
            let formatted = compact
                ? RadarFormatters.compact(metric.value)
                : RadarFormatters.number(metric.value)

            guard let unit else {
                return formatted
            }

            return "\(formatted) \(unit)"
        }
    }

    static func change(_ change: FinancialChange, compact: Bool = false) -> String {
        switch change.format {
        case .percentage:
            return signedRate(change.value)
        case let .currency(code):
            let absolute = abs(change.value)
            let formatted = currency(absolute, code: code)
            return change.value >= 0 ? "+\(formatted)" : "-\(formatted)"
        case let .number(unit):
            let absolute = abs(change.value)
            let formatted = compact
                ? RadarFormatters.compact(absolute)
                : RadarFormatters.number(absolute)
            let value = unit.map { "\(formatted) \($0)" } ?? formatted
            return change.value >= 0 ? "+\(value)" : "-\(value)"
        }
    }

    static func shortDate(_ date: Date) -> String {
        date.formatted(
            .dateTime
                .day(.twoDigits)
                .month(.abbreviated)
                .locale(locale)
        )
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
