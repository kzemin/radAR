import SwiftUI

enum TickerItem: Identifiable, Hashable {
    case quote(label: String, value: String, change: String?)
    case stat(label: String, value: String)
    case urgent(String)

    var id: String {
        switch self {
        case let .quote(label, _, _): "q-\(label)"
        case let .stat(label, _): "s-\(label)"
        case let .urgent(text): "u-\(text)"
        }
    }
}

struct NewsTickerBar: View {
    let items: [TickerItem]
    var pointsPerSecond: CGFloat = 48
    var height: CGFloat = 35

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
        HStack(spacing: 6) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                itemView(item)
                separator
            }
        }
        .padding(.horizontal, 10)
        .fixedSize()
    }

    private var separator: some View {
        Text("·")
            .font(RadarTheme.Typography.compactLabel)
            .foregroundStyle(MapaTheme.Colors.borderStrong)
    }

    @ViewBuilder
    private func itemView(_ item: TickerItem) -> some View {
        switch item {
        case let .quote(label, value, change):
            HStack(spacing: 6) {
                Text(label)
                    .textStyle(.tickerLabel)
                    .foregroundStyle(MapaTheme.Colors.textTertiary)

                Text(value)
                    .textStyle(.tickerValue)
                    .foregroundStyle(MapaTheme.Colors.textPrimary)

                if let change {
                    Text(change)
                        .textStyle(.tickerValue)
                        .foregroundStyle(changeColor(for: change))
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
        }
    }

    private func changeColor(for change: String) -> Color {
        change.hasPrefix("-") ? MapaTheme.Colors.negative : MapaTheme.Colors.positive
    }
}

private struct TickerRowWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
