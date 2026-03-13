import Charts
import SwiftUI

private enum MarketMonitorLayout {
    static let instrumentWidth: CGFloat = 176
    static let marketWidth: CGFloat = 76
    static let lastWidth: CGFloat = 92
    static let deltaWidth: CGFloat = 92
    static let changeWidth: CGFloat = 72
    static let sparklineWidth: CGFloat = 70
    static let updatedWidth: CGFloat = 68
    static let actionWidth: CGFloat = 42

    static func totalWidth() -> CGFloat {
        instrumentWidth + marketWidth + lastWidth + deltaWidth + changeWidth + sparklineWidth + updatedWidth + actionWidth
    }
}

struct MarketMonitorRow<TrailingContent: View>: View {
    let quote: MarketQuote
    let metric: FinancialMetric
    let absoluteChange: FinancialChange?
    let percentageChange: Double
    let sparklinePoints: [MarketPoint]
    let updatedAt: Date
    let statusStyle: StatusChipStyle
    var subtitle: String?
    var isSelected = false
    var isHighlighted = false
    private let trailingContent: TrailingContent
    let onSelect: (() -> Void)?

    init(
        quote: MarketQuote,
        metric: FinancialMetric,
        absoluteChange: FinancialChange?,
        percentageChange: Double,
        sparklinePoints: [MarketPoint],
        updatedAt: Date,
        statusStyle: StatusChipStyle,
        subtitle: String? = nil,
        isSelected: Bool = false,
        isHighlighted: Bool = false,
        onSelect: (() -> Void)? = nil,
        @ViewBuilder trailingContent: () -> TrailingContent
    ) {
        self.quote = quote
        self.metric = metric
        self.absoluteChange = absoluteChange
        self.percentageChange = percentageChange
        self.sparklinePoints = sparklinePoints
        self.updatedAt = updatedAt
        self.statusStyle = statusStyle
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.isHighlighted = isHighlighted
        self.onSelect = onSelect
        self.trailingContent = trailingContent()
    }

    private var resolvedSubtitle: String {
        subtitle ?? "\(quote.name) · \(RadarFormatters.shortTime(updatedAt))"
    }

    var body: some View {
        DataRow(
            title: quote.symbol,
            subtitle: resolvedSubtitle,
            leadingTag: quote.market,
            leadingTagStyle: statusStyle,
            metric: metric,
            absoluteChange: absoluteChange,
            percentageChange: percentageChange,
            sparklinePoints: sparklinePoints,
            sparklineTrend: percentageChange,
            compactNumbers: true,
            isHighlighted: isSelected || isHighlighted
        ) {
            trailingContent
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect?()
        }
    }
}

extension MarketMonitorRow where TrailingContent == EmptyView {
    init(
        quote: MarketQuote,
        metric: FinancialMetric,
        absoluteChange: FinancialChange?,
        percentageChange: Double,
        sparklinePoints: [MarketPoint],
        updatedAt: Date,
        statusStyle: StatusChipStyle,
        subtitle: String? = nil,
        isSelected: Bool = false,
        isHighlighted: Bool = false,
        onSelect: (() -> Void)? = nil
    ) {
        self.init(
            quote: quote,
            metric: metric,
            absoluteChange: absoluteChange,
            percentageChange: percentageChange,
            sparklinePoints: sparklinePoints,
            updatedAt: updatedAt,
            statusStyle: statusStyle,
            subtitle: subtitle,
            isSelected: isSelected,
            isHighlighted: isHighlighted,
            onSelect: onSelect
        ) {
            EmptyView()
        }
    }
}

struct MarketOverviewTileView: View {
    let quote: MarketQuote
    let metric: FinancialMetric
    let absoluteChange: FinancialChange?
    let percentageChange: Double
    let sparklinePoints: [MarketPoint]
    let updatedAt: Date
    let statusStyle: StatusChipStyle
    var isSelected = false
    var isExpanded = false
    let onSelect: () -> Void
    var onToggleExpansion: (() -> Void)? = nil

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: RadarTheme.Spacing.row) {
                    VStack(alignment: .leading, spacing: RadarTheme.Spacing.micro) {
                        Text(quote.symbol)
                            .font(RadarTheme.Typography.compactLabel)
                            .foregroundStyle(RadarTheme.Colors.textPrimary)

                        Text(quote.name)
                            .font(RadarTheme.Typography.panelSubtitle)
                            .foregroundStyle(RadarTheme.Colors.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: RadarTheme.Spacing.small)

                    StatusChip(title: quote.market.uppercased(), style: statusStyle)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)

                PanelDivider()

                HStack(alignment: .top, spacing: RadarTheme.Spacing.row) {
                    FinancialValue(
                        metric: metric,
                        absoluteChange: isExpanded ? absoluteChange : nil,
                        percentageChange: percentageChange,
                        compactNumbers: true,
                        valueFont: isExpanded ? RadarTheme.Typography.largeValue : RadarTheme.Typography.value
                    )

                    MiniSparkline(
                        points: sparklinePoints,
                        trend: percentageChange,
                        showsArea: true
                    )
                    .frame(width: isExpanded ? 112 : 74, height: isExpanded ? 40 : 32)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)

                PanelDivider()

                HStack {
                    PanelTimestamp(value: RadarFormatters.shortTime(updatedAt))
                    Spacer()

                    if isSelected {
                        StatusChip(title: "ACTIVE", style: .accent)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 7)

                if isExpanded {
                    PanelDivider()

                    HStack(spacing: RadarTheme.Spacing.row) {
                        PanelTimestamp(title: "Activo", value: quote.symbol)
                        Spacer(minLength: RadarTheme.Spacing.row)
                        PanelTimestamp(title: "Serie", value: "30D")
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 7)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .background(RadarTheme.Colors.surface.opacity(0.001))
            .overlay(
                Rectangle()
                    .stroke(
                        isSelected ? RadarTheme.Colors.accent : RadarTheme.Colors.border,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.3)
                .onEnded { _ in
                    onToggleExpansion?()
                }
        )
    }
}

struct MarketRangeSelector: View {
    @Binding var selectedRange: MarketRange

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MarketRange.allCases) { range in
                Button {
                    selectedRange = range
                } label: {
                    Text(range.rawValue)
                        .font(RadarTheme.Typography.compactLabel)
                        .foregroundStyle(
                            selectedRange == range
                                ? RadarTheme.Colors.textPrimary
                                : RadarTheme.Colors.textSecondary
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(
                            selectedRange == range
                                ? RadarTheme.Colors.backgroundElevated
                                : Color.clear
                        )
                }
                .buttonStyle(.plain)

                if range != MarketRange.allCases.last {
                    Rectangle()
                        .fill(RadarTheme.Colors.separator)
                        .frame(width: 1)
                }
            }
        }
        .overlay(
            Rectangle()
                .stroke(RadarTheme.Colors.border, lineWidth: 1)
        )
    }
}

struct MarketDetailChartView: View {
    let quote: MarketQuote
    let priceMetric: FinancialMetric
    let dayAbsoluteChange: FinancialChange?
    let dayPercentageChange: Double
    let rangeAbsoluteChange: FinancialChange?
    let rangePercentageChange: Double?
    let points: [MarketPoint]
    let range: MarketRange
    let rangeStartValue: Double?
    let rangeHighLow: (high: Double, low: Double)?
    let updatedAt: Date
    let statusStyle: StatusChipStyle
    let isTracked: Bool
    let onToggleWatchlist: () -> Void
    @Binding var selectedRange: MarketRange

    private var trendColor: Color {
        let change = rangePercentageChange ?? dayPercentageChange

        if change > 0 {
            return RadarTheme.Colors.positive
        }

        if change < 0 {
            return RadarTheme.Colors.negative
        }

        return RadarTheme.Colors.accent
    }

    var body: some View {
        MonitorFrame {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: RadarTheme.Spacing.row) {
                    VStack(alignment: .leading, spacing: RadarTheme.Spacing.micro) {
                        HStack(spacing: RadarTheme.Spacing.small) {
                            Text(quote.symbol)
                                .font(RadarTheme.Typography.panelTitle)
                                .foregroundStyle(RadarTheme.Colors.textPrimary)

                            StatusChip(title: quote.market.uppercased(), style: statusStyle)
                        }

                        Text(quote.name)
                            .font(RadarTheme.Typography.panelSubtitle)
                            .foregroundStyle(RadarTheme.Colors.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: RadarTheme.Spacing.row)

                    TerminalButton(
                        title: isTracked ? "TRACKED" : "WATCH",
                        style: isTracked ? .primary : .secondary,
                        action: onToggleWatchlist
                    )
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)

                PanelDivider()

                HStack(alignment: .top, spacing: RadarTheme.Spacing.row) {
                    FinancialValue(
                        metric: priceMetric,
                        absoluteChange: dayAbsoluteChange,
                        percentageChange: dayPercentageChange,
                        compactNumbers: true,
                        valueFont: RadarTheme.Typography.largeValue
                    )

                    Spacer(minLength: RadarTheme.Spacing.row)

                    VStack(alignment: .trailing, spacing: RadarTheme.Spacing.micro) {
                        Text("PERF \(range.rawValue)")
                            .font(RadarTheme.Typography.compactTag)
                            .foregroundStyle(RadarTheme.Colors.textTertiary)

                        if let rangeAbsoluteChange {
                            Text(RadarFormatters.change(rangeAbsoluteChange, compact: true))
                                .font(RadarTheme.Typography.compactLabel)
                                .foregroundStyle(trendColor)
                                .monospacedDigit()
                        }

                        if let rangePercentageChange {
                            Text(RadarFormatters.signedRate(rangePercentageChange))
                                .font(RadarTheme.Typography.compactLabel)
                                .foregroundStyle(trendColor)
                                .monospacedDigit()
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)

                PanelDivider()

                HStack(spacing: RadarTheme.Spacing.row) {
                    MarketRangeSelector(selectedRange: $selectedRange)
                        .frame(maxWidth: 192)

                    Spacer(minLength: RadarTheme.Spacing.row)

                    PanelTimestamp(value: RadarFormatters.timestamp(updatedAt))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)

                PanelDivider()

                Chart {
                    if let lastValue = points.last?.value {
                        RuleMark(y: .value("Último", lastValue))
                            .lineStyle(.init(lineWidth: 1, dash: [2, 3]))
                            .foregroundStyle(RadarTheme.Colors.textTertiary.opacity(0.55))
                    }

                    ForEach(points) { point in
                        LineMark(
                            x: .value("Fecha", point.date),
                            y: .value("Valor", point.value)
                        )
                        .interpolationMethod(.linear)
                        .lineStyle(.init(lineWidth: 1.35))
                        .foregroundStyle(trendColor)

                        AreaMark(
                            x: .value("Fecha", point.date),
                            y: .value("Valor", point.value)
                        )
                        .interpolationMethod(.linear)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    trendColor.opacity(0.16),
                                    trendColor.opacity(0.02)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.6))
                            .foregroundStyle(RadarTheme.Colors.separator)

                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                            .font(RadarTheme.Typography.compactTag)
                            .foregroundStyle(RadarTheme.Colors.textTertiary)
                    }
                }
                .chartYAxis(.hidden)
                .chartLegend(.hidden)
                .chartPlotStyle { plot in
                    plot
                        .background(Color.clear)
                }
                .frame(height: 212)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)

                PanelDivider()

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: RadarTheme.Spacing.compact),
                        GridItem(.flexible(), spacing: RadarTheme.Spacing.compact),
                        GridItem(.flexible(), spacing: RadarTheme.Spacing.compact),
                    ],
                    spacing: RadarTheme.Spacing.compact
                ) {
                    MarketDetailStatView(
                        title: "Inicio \(range.rawValue)",
                        value: formattedValue(rangeStartValue)
                    )
                    MarketDetailStatView(
                        title: "Máximo",
                        value: formattedValue(rangeHighLow?.high)
                    )
                    MarketDetailStatView(
                        title: "Mínimo",
                        value: formattedValue(rangeHighLow?.low)
                    )
                    MarketDetailStatView(
                        title: "Moneda",
                        value: quote.currencyCode
                    )
                    MarketDetailStatView(
                        title: "Último dato",
                        value: RadarFormatters.shortTime(updatedAt)
                    )
                    MarketDetailStatView(
                        title: "Serie",
                        value: "\(points.count) puntos"
                    )
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            }
        }
    }

    private func formattedValue(_ value: Double?) -> String {
        RadarFormatters.metric(
            FinancialMetric(value: value, format: priceMetric.format),
            compact: true
        )
    }
}

private struct MarketDetailStatView: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: RadarTheme.Spacing.micro) {
            Text(title.uppercased())
                .font(RadarTheme.Typography.compactTag)
                .foregroundStyle(RadarTheme.Colors.textTertiary)

            Text(value)
                .font(RadarTheme.Typography.compactLabel)
                .foregroundStyle(RadarTheme.Colors.textPrimary)
                .monospacedDigit()
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MarketWatchlistRowView: View {
    let quote: MarketQuote
    let metric: FinancialMetric
    let absoluteChange: FinancialChange?
    let percentageChange: Double
    let sparklinePoints: [MarketPoint]
    let updatedAt: Date
    let statusStyle: StatusChipStyle
    let isSelected: Bool
    let isTracked: Bool
    let onSelect: () -> Void
    let onToggleWatchlist: () -> Void

    var body: some View {
        MarketMonitorRow(
            quote: quote,
            metric: metric,
            absoluteChange: absoluteChange,
            percentageChange: percentageChange,
            sparklinePoints: sparklinePoints,
            updatedAt: updatedAt,
            statusStyle: statusStyle,
            isSelected: isSelected,
            onSelect: onSelect
        ) {
            MarketWatchToggleView(
                isTracked: isTracked,
                onToggle: onToggleWatchlist
            )
        }
    }
}

struct MarketIndicatorRowView: View {
    let indicator: MarketIndicator
    let metric: FinancialMetric

    private var subtitle: String {
        if let change = indicator.changePercentage {
            return "Variación \(RadarFormatters.signedRate(change)) · \(indicator.unit)"
        }

        return "Unidad: \(indicator.unit)"
    }

    var body: some View {
        DataRow(
            title: indicator.name,
            subtitle: subtitle,
            metric: metric,
            percentageChange: indicator.changePercentage,
            compactNumbers: true
        )
    }
}

struct MarketQuoteTableView: View {
    let quotes: [MarketQuote]
    let selectedQuoteID: String?
    let metricProvider: (MarketQuote) -> FinancialMetric
    let absoluteChangeProvider: (MarketQuote) -> FinancialChange?
    let updatedInfoProvider: (MarketQuote) -> String
    let sparklineProvider: (MarketQuote) -> [MarketPoint]
    let statusStyleProvider: (MarketQuote) -> StatusChipStyle
    let isTracked: (MarketQuote) -> Bool
    let onSelect: (MarketQuote) -> Void
    let onToggleWatchlist: (MarketQuote) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            MonitorFrame {
                VStack(spacing: 0) {
                    MarketQuoteTableHeader()
                    PanelDivider()

                    ForEach(quotes) { quote in
                        MarketQuoteTableRowView(
                            quote: quote,
                            metric: metricProvider(quote),
                            absoluteChange: absoluteChangeProvider(quote),
                            updatedInfo: updatedInfoProvider(quote),
                            sparklinePoints: sparklineProvider(quote),
                            statusStyle: statusStyleProvider(quote),
                            isSelected: selectedQuoteID == quote.id,
                            isTracked: isTracked(quote),
                            onSelect: { onSelect(quote) },
                            onToggleWatchlist: { onToggleWatchlist(quote) }
                        )

                        if quote.id != quotes.last?.id {
                            PanelDivider()
                        }
                    }
                }
                .frame(minWidth: MarketMonitorLayout.totalWidth(), alignment: .leading)
            }
        }
    }
}

private struct MarketQuoteTableHeader: View {
    var body: some View {
        HStack(spacing: 0) {
            headerCell("Instrumento", width: MarketMonitorLayout.instrumentWidth, alignment: .leading)
            headerCell("Mercado", width: MarketMonitorLayout.marketWidth, alignment: .leading)
            headerCell("Último", width: MarketMonitorLayout.lastWidth, alignment: .trailing)
            headerCell("Δ", width: MarketMonitorLayout.deltaWidth, alignment: .trailing)
            headerCell("%", width: MarketMonitorLayout.changeWidth, alignment: .trailing)
            headerCell("Trend", width: MarketMonitorLayout.sparklineWidth, alignment: .center)
            headerCell("Upd.", width: MarketMonitorLayout.updatedWidth, alignment: .leading)
            headerCell("Fav", width: MarketMonitorLayout.actionWidth, alignment: .center)
        }
        .background(RadarTheme.Colors.backgroundElevated.opacity(0.6))
    }

    private func headerCell(_ title: String, width: CGFloat, alignment: Alignment) -> some View {
        Text(title.uppercased())
            .font(RadarTheme.Typography.compactTag)
            .tracking(0.6)
            .foregroundStyle(RadarTheme.Colors.textSecondary)
            .frame(width: width, alignment: alignment)
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
    }
}

private struct MarketQuoteTableRowView: View {
    let quote: MarketQuote
    let metric: FinancialMetric
    let absoluteChange: FinancialChange?
    let updatedInfo: String
    let sparklinePoints: [MarketPoint]
    let statusStyle: StatusChipStyle
    let isSelected: Bool
    let isTracked: Bool
    let onSelect: () -> Void
    let onToggleWatchlist: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text(quote.symbol)
                    .font(RadarTheme.Typography.rowLabel)
                    .foregroundStyle(RadarTheme.Colors.textPrimary)
                    .lineLimit(1)

                Text(quote.name)
                    .font(RadarTheme.Typography.panelSubtitle)
                    .foregroundStyle(RadarTheme.Colors.textSecondary)
                    .lineLimit(2)
            }
            .frame(width: MarketMonitorLayout.instrumentWidth, alignment: .leading)
            .padding(.vertical, 8)
            .padding(.horizontal, 6)

            Text(quote.market.uppercased())
                .font(RadarTheme.Typography.compactLabel)
                .foregroundStyle(statusTextColor)
                .frame(width: MarketMonitorLayout.marketWidth, alignment: .leading)
                .padding(.vertical, 8)
                .padding(.horizontal, 6)

            valueCell(RadarFormatters.metric(metric, compact: true), width: MarketMonitorLayout.lastWidth)
            valueCell(
                absoluteChange.map { RadarFormatters.change($0, compact: true) } ?? "—",
                width: MarketMonitorLayout.deltaWidth,
                tint: changeColor
            )
            valueCell(
                RadarFormatters.signedRate(quote.changePercentage),
                width: MarketMonitorLayout.changeWidth,
                tint: changeColor
            )

            MiniSparkline(
                points: sparklinePoints,
                trend: quote.changePercentage
            )
            .frame(width: MarketMonitorLayout.sparklineWidth, height: 22)
            .padding(.vertical, 8)
            .padding(.horizontal, 6)

            Text(updatedInfo)
                .font(RadarTheme.Typography.compactLabel)
                .foregroundStyle(RadarTheme.Colors.textSecondary)
                .frame(width: MarketMonitorLayout.updatedWidth, alignment: .leading)
                .padding(.vertical, 8)
                .padding(.horizontal, 6)

            MarketRowIconButton(
                systemImage: isTracked ? "star.fill" : "star",
                tint: isTracked ? RadarTheme.Colors.warning : RadarTheme.Colors.textSecondary,
                accessibilityLabel: isTracked ? "Quitar de watchlist" : "Agregar a watchlist",
                action: onToggleWatchlist
            )
            .frame(width: MarketMonitorLayout.actionWidth)
            .padding(.vertical, 6)
        }
        .background(isSelected ? RadarTheme.Colors.accent.opacity(0.08) : .clear)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
    }

    private var changeColor: Color {
        if quote.changePercentage > 0 {
            return RadarTheme.Colors.positive
        }

        if quote.changePercentage < 0 {
            return RadarTheme.Colors.negative
        }

        return RadarTheme.Colors.textSecondary
    }

    private var statusTextColor: Color {
        switch statusStyle {
        case .accent, .live:
            return RadarTheme.Colors.accent
        case .warning:
            return RadarTheme.Colors.warning
        case .negative, .alert:
            return RadarTheme.Colors.negative
        case .positive:
            return RadarTheme.Colors.positive
        default:
            return RadarTheme.Colors.textSecondary
        }
    }

    private func valueCell(
        _ value: String,
        width: CGFloat,
        tint: Color = RadarTheme.Colors.textPrimary
    ) -> some View {
        Text(value)
            .font(RadarTheme.Typography.compactLabel)
            .foregroundStyle(tint)
            .monospacedDigit()
            .frame(width: width, alignment: .trailing)
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
    }
}

private struct MarketRowIconButton: View {
    let systemImage: String
    let tint: Color
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 24, height: 22)
                .background(RadarTheme.Colors.backgroundElevated)
                .overlay(
                    Rectangle()
                        .stroke(RadarTheme.Colors.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

struct MarketWatchToggleView: View {
    let isTracked: Bool
    let onToggle: () -> Void

    var body: some View {
        MarketRowIconButton(
            systemImage: isTracked ? "star.fill" : "star",
            tint: isTracked ? RadarTheme.Colors.warning : RadarTheme.Colors.textSecondary,
            accessibilityLabel: isTracked ? "Quitar de watchlist" : "Agregar a watchlist",
            action: onToggle
        )
    }
}

@MainActor
private struct MarketOverviewTilePreviewScene: View {
    private let store = MarketFixturesPreview.previewStore()
    private var quote: MarketQuote { store.overviewTiles[0] }

    var body: some View {
        MarketOverviewTileView(
            quote: quote,
            metric: store.metric(for: quote),
            absoluteChange: store.dayAbsoluteChange(for: quote),
            percentageChange: quote.changePercentage,
            sparklinePoints: store.sparklinePoints(for: quote),
            updatedAt: store.updatedAt(for: quote),
            statusStyle: store.marketTagStyle(for: quote),
            isSelected: true,
            onSelect: {}
        )
        .padding()
        .background(TerminalScreenBackground())
    }
}

#Preview("Market Overview Tile") {
    MarketOverviewTilePreviewScene()
}

@MainActor
private struct MarketTablePreviewScene: View {
    private let store = MarketFixturesPreview.previewStore()

    var body: some View {
        MarketQuoteTableView(
            quotes: store.quoteRows,
            selectedQuoteID: store.selectedQuoteID,
            metricProvider: { store.metric(for: $0) },
            absoluteChangeProvider: { store.dayAbsoluteChange(for: $0) },
            updatedInfoProvider: { RadarFormatters.shortTime(store.updatedAt(for: $0)) },
            sparklineProvider: { store.sparklinePoints(for: $0) },
            statusStyleProvider: { store.marketTagStyle(for: $0) },
            isTracked: { store.isInWatchlist($0) },
            onSelect: { _ in },
            onToggleWatchlist: { _ in }
        )
        .padding()
        .background(TerminalScreenBackground())
    }
}

#Preview("Market Table") {
    MarketTablePreviewScene()
}
