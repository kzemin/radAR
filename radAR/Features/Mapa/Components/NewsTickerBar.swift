import SwiftUI

enum TickerItem: Identifiable, Hashable {
    case quote(label: String, value: String, change: String?)
    case stat(label: String, value: String)
    case urgent(String)
    /// A tappable national headline. `eventID` is the `NewsEvent.id` as a string so
    /// the ticker stays decoupled from the model; the host resolves it back.
    case news(eventID: String, kicker: String, text: String, breaking: Bool)

    var id: String {
        switch self {
        case let .quote(label, _, _): "q-\(label)"
        case let .stat(label, _): "s-\(label)"
        case let .urgent(text): "u-\(text)"
        case let .news(eventID, _, _, _): "n-\(eventID)"
        }
    }
}

struct NewsTickerBar: View {
    let items: [TickerItem]
    var pointsPerSecond: CGFloat = 48
    var height: CGFloat = 35
    var onTapNews: ((String) -> Void)? = nil

    @State private var rowWidth: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            scrollingContent
                .frame(width: proxy.size.width, height: height, alignment: .leading)
                .clipped()
                .background(MapaTheme.Colors.mapWorldLand)
                .overlay(alignment: .top) {
                    Rectangle().fill(MapaTheme.Colors.border).frame(height: 1)
                }
                .overlay(alignment: .bottom) {
                    Rectangle().fill(MapaTheme.Colors.border).frame(height: 1)
                }
        }
        .frame(height: height)
        .onPreferenceChange(TickerRowWidthKey.self) { width in
            if width > 0, abs(width - rowWidth) > 0.5 {
                rowWidth = width
            }
        }
    }

    private var scrollingContent: some View {
        TimelineView(.animation) { context in
            HStack(spacing: 0) {
                row
                    .background(
                        GeometryReader { proxy in
                            Color.clear.preference(key: TickerRowWidthKey.self, value: proxy.size.width)
                        }
                    )
                row
            }
            .offset(x: offset(for: context.date))
        }
    }

    private func offset(for date: Date) -> CGFloat {
        guard rowWidth > 0 else { return 0 }
        let elapsed = CGFloat(date.timeIntervalSinceReferenceDate)
        let traveled = elapsed * pointsPerSecond
        return -traveled.truncatingRemainder(dividingBy: rowWidth)
    }

    private var row: some View {
        // Wider spacing around each vertical rule so the grid lines breathe
        // between items instead of feeling crammed against the text.
        HStack(spacing: 12) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                itemView(item)
                separator
            }
        }
        .padding(.horizontal, 10)
        .fixedSize()
    }

    private var separator: some View {
        // Full-height 1pt rule between items — same width and color as the
        // ticker's top/bottom borders, so the strip reads as a clean grid
        // instead of a bullet-separated list.
        Rectangle()
            .fill(MapaTheme.Colors.border)
            .frame(width: 1, height: height)
    }

    @ViewBuilder
    private func itemView(_ item: TickerItem) -> some View {
        switch item {
        case let .quote(label, value, change):
            // Value tints to the change color so the whole quote reads as up/down.
            let valueColor = change.map(changeColor(for:)) ?? MapaTheme.Colors.textPrimary
            HStack(spacing: 6) {
                Text(label)
                    .textStyle(.tickerLabel)
                    .foregroundStyle(MapaTheme.Colors.textTertiary)

                Text(coloredValue(value, numberColor: valueColor))
                    .textStyle(.tickerValue)

                if let change {
                    // Solid sharp-cornered badge to match the rest of the app's
                    // Rectangle-based chrome (drawer, callout borders, dividers).
                    // Smaller font + tight padding so it sits within the value's height.
                    Text(change)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(changeColor(for: change))
                }
            }

        case let .stat(label, value):
            HStack(spacing: 6) {
                Text(label)
                    .textStyle(.tickerLabel)
                    .foregroundStyle(MapaTheme.Colors.textTertiary)

                Text(value)
                    .textStyle(.tickerValue)
                    .foregroundStyle(MapaTheme.Colors.textPrimary)
            }

        case let .urgent(text):
            HStack(spacing: 0) {
                Text("Urgente".uppercased())
                    .textStyle(.tickerUrgentLabel)
                    .foregroundStyle(MapaTheme.Colors.textInverse)
                    .padding(.horizontal, 8)
                    .frame(maxHeight: .infinity)
                    .background(MapaTheme.Colors.accent)

                Text(text)
                    .textStyle(.tickerUrgent)
                    .foregroundStyle(.white)
                    .padding(.leading, 8)
            }
            .frame(height: height)

        case let .news(eventID, kicker, text, breaking):
            HStack(spacing: 0) {
                Text((breaking ? "Urgente" : kicker).uppercased())
                    .textStyle(.tickerUrgentLabel)
                    .foregroundStyle(MapaTheme.Colors.textInverse)
                    .padding(.horizontal, 8)
                    .frame(maxHeight: .infinity)
                    .background(breaking ? MapaTheme.Colors.accent : MapaTheme.Colors.info)

                Text(text)
                    .textStyle(.tickerUrgent)
                    .foregroundStyle(breaking ? .white : MapaTheme.Colors.textPrimary)
                    .padding(.leading, 8)
            }
            .frame(height: height)
            .contentShape(Rectangle())
            .onTapGesture { onTapNews?(eventID) }
        }
    }

    private func changeColor(for change: String) -> Color {
        change.hasPrefix("-") ? MapaTheme.Colors.negative : MapaTheme.Colors.positive
    }

    /// Tints the numeric parts of a quote with `numberColor` while keeping the
    /// "C:" / "V:" labels and the "|" separator white — neutral chrome around
    /// the colored figures (e.g. `C: $1.380,00 | V: $1.430,00`).
    private func coloredValue(_ value: String, numberColor: Color) -> AttributedString {
        var result = AttributedString()
        let tokens = value.split(separator: " ", omittingEmptySubsequences: false)
        for (index, token) in tokens.enumerated() {
            var piece = AttributedString(String(token))
            let isLabel = token == "C:" || token == "V:" || token == "|"
            piece.foregroundColor = isLabel ? MapaTheme.Colors.textPrimary : numberColor
            result.append(piece)
            if index < tokens.count - 1 { result.append(AttributedString(" ")) }
        }
        return result
    }
}

private struct TickerRowWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
