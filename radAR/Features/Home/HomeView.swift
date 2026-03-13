import SwiftUI

struct HomeView: View {
    let monitorStore: MarketStore
    @State private var expandedOverviewTileID: String?

    private let compactOverviewTileHeight: CGFloat = 134
    private let expandedOverviewTileHeight: CGFloat = 186

    init(monitorStore: MarketStore) {
        self.monitorStore = monitorStore
    }

    private var overviewUpdatedText: String {
        guard let updatedAt = monitorStore.overviewUpdatedAt else {
            return "Sin dato"
        }

        return RadarFormatters.timestamp(updatedAt)
    }

    private var overviewRows: [[MarketQuote]] {
        let quotes = monitorStore.overviewTiles
        return stride(from: 0, to: quotes.count, by: 2).map { index in
            Array(quotes[index..<min(index + 2, quotes.count)])
        }
    }

    var body: some View {
        ZStack {
            TerminalScreenBackground()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: RadarTheme.Spacing.section) {
                    content
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(RadarTheme.Spacing.screen)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await monitorStore.loadIfNeeded()
        }
        .refreshable {
            await monitorStore.refresh()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch monitorStore.state {
        case .idle, .loading:
            LoadingStateView(title: "Actualizando monitor global")
        case let .empty(message):
            EmptyStateView(title: "Sin mercado", message: message)
        case let .failed(error):
            ErrorStateView(
                title: "Monitor no disponible",
                message: error.localizedDescription,
                retryAction: {
                    Task {
                        await monitorStore.refresh()
                    }
                }
            )
        case .loaded:
            overviewPanel
            detailPanel
            watchlistPanel
            quotesPanel
            variablesPanel
        }
    }

    private var overviewPanel: some View {
        DashboardPanel(
            title: "Home Monitor",
            subtitle: "radAR · monitoreo de mercado BCRA",
            metadataItems: [
                PanelMetadataItem(title: "Universe", value: "\(monitorStore.quoteRows.count)"),
                PanelMetadataItem(title: "Watch", value: "\(monitorStore.watchlistCount)"),
                PanelMetadataItem.updated(overviewUpdatedText)
            ],
            badges: [
                PanelBadge("LIVE", style: .live),
                PanelBadge("BCRA", style: .category),
                PanelBadge("MONITOR", style: .neutral)
            ]
        ) {
            VStack(alignment: .leading, spacing: RadarTheme.Spacing.compact) {
                ForEach(Array(overviewRows.enumerated()), id: \.offset) { _, row in
                    overviewRow(row)
                }
            }
            .animation(.snappy(duration: 0.32, extraBounce: 0.08), value: expandedOverviewTileID)
        }
    }

    @ViewBuilder
    private func overviewRow(_ row: [MarketQuote]) -> some View {
        GeometryReader { geometry in
            let spacing = RadarTheme.Spacing.compact
            let compactWidth = (geometry.size.width - spacing) / 2

            if let expandedQuote = row.first(where: { $0.id == expandedOverviewTileID }) {
                VStack(alignment: .leading, spacing: spacing) {
                    overviewTile(expandedQuote, expanded: true)
                        .frame(width: geometry.size.width, height: expandedOverviewTileHeight)

                    if let displacedQuote = row.first(where: { $0.id != expandedQuote.id }) {
                        HStack(alignment: .top, spacing: spacing) {
                            overviewTile(displacedQuote, expanded: false)
                                .frame(width: compactWidth, height: compactOverviewTileHeight)

                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .opacity))
            } else {
                HStack(alignment: .top, spacing: spacing) {
                    ForEach(row) { quote in
                        overviewTile(quote, expanded: false)
                            .frame(
                                width: row.count == 1 ? geometry.size.width : compactWidth,
                                height: compactOverviewTileHeight
                            )
                    }

                    if row.count == 1 {
                        Color.clear
                            .frame(width: 0, height: compactOverviewTileHeight)
                    }
                }
                .transition(.opacity)
            }
        }
        .frame(height: overviewRowHeight(for: row))
    }

    private func overviewTile(_ quote: MarketQuote, expanded: Bool) -> some View {
        MarketOverviewTileView(
            quote: quote,
            metric: monitorStore.metric(for: quote),
            absoluteChange: monitorStore.dayAbsoluteChange(for: quote),
            percentageChange: quote.changePercentage,
            sparklinePoints: monitorStore.sparklinePoints(for: quote),
            updatedAt: monitorStore.updatedAt(for: quote),
            statusStyle: monitorStore.marketTagStyle(for: quote),
            isSelected: monitorStore.selectedQuoteID == quote.id,
            isExpanded: expanded,
            onSelect: {
                monitorStore.selectQuote(quote)
            },
            onToggleExpansion: {
                withAnimation(.snappy(duration: 0.32, extraBounce: 0.08)) {
                    expandedOverviewTileID = expanded ? nil : quote.id
                }
            }
        )
    }

    private func overviewRowHeight(for row: [MarketQuote]) -> CGFloat {
        if row.contains(where: { $0.id == expandedOverviewTileID }) {
            return expandedOverviewTileHeight + (row.count > 1 ? RadarTheme.Spacing.compact + compactOverviewTileHeight : 0)
        }

        return compactOverviewTileHeight
    }

    @ViewBuilder
    private var detailPanel: some View {
        if let quote = monitorStore.selectedQuote, let metric = monitorStore.selectedMetric {
            @Bindable var monitorStore = monitorStore

            DashboardPanel(
                title: "Detail Monitor",
                metadataItems: [
                    PanelMetadataItem(title: "Range", value: monitorStore.selectedRange.rawValue),
                    PanelMetadataItem(title: "Points", value: "\(monitorStore.visibleSeries.count)"),
                    PanelMetadataItem.updated(RadarFormatters.timestamp(monitorStore.updatedAt(for: quote)))
                ],
                badges: [
                    PanelBadge(quote.market.uppercased(), style: monitorStore.marketTagStyle(for: quote))
                ]
            ) {
                HStack(alignment: .firstTextBaseline, spacing: RadarTheme.Spacing.small) {
                    StatusChip(title: "Seleccionado", style: .accent)

                    Text("\(quote.symbol) · \(quote.name)")
                        .font(RadarTheme.Typography.panelSubtitle)
                        .foregroundStyle(RadarTheme.Colors.textSecondary)
                        .lineLimit(2)
                }

                MarketDetailChartView(
                    quote: quote,
                    priceMetric: metric,
                    dayAbsoluteChange: monitorStore.selectedAbsoluteChange,
                    dayPercentageChange: quote.changePercentage,
                    rangeAbsoluteChange: monitorStore.selectedRangeAbsoluteChange,
                    rangePercentageChange: monitorStore.selectedRangePercentageChange,
                    points: monitorStore.visibleSeries,
                    range: monitorStore.selectedRange,
                    rangeStartValue: monitorStore.rangeStartValue(for: quote, range: monitorStore.selectedRange),
                    rangeHighLow: monitorStore.rangeHighLow(for: quote, range: monitorStore.selectedRange),
                    updatedAt: monitorStore.updatedAt(for: quote),
                    statusStyle: monitorStore.marketTagStyle(for: quote),
                    isTracked: monitorStore.isInWatchlist(quote),
                    onToggleWatchlist: {
                        monitorStore.toggleWatchlist(quote)
                    },
                    selectedRange: $monitorStore.selectedRange
                )
            }
        }
    }

    private var watchlistPanel: some View {
        DashboardPanel(
            title: "Watchlist",
            subtitle: "Seguimiento local de variables priorizadas",
            metadataItems: [
                PanelMetadataItem(title: "Saved", value: "\(monitorStore.watchlistCount)"),
                PanelMetadataItem(title: "Shown", value: "\(monitorStore.watchlistQuotes.count)"),
                PanelMetadataItem.updated(overviewUpdatedText)
            ],
            badges: [
                PanelBadge("WATCH", style: .accent)
            ]
        ) {
            if monitorStore.watchlistQuotes.isEmpty {
                MonitorFrame {
                    VStack(alignment: .leading, spacing: RadarTheme.Spacing.small) {
                        Text("Todavía no seguís ningún activo.")
                            .font(RadarTheme.Typography.compactLabel)
                            .foregroundStyle(RadarTheme.Colors.textPrimary)

                        Text("Marcá una estrella en el market tape para sumarlo a esta watchlist y seguirlo de cerca.")
                            .font(RadarTheme.Typography.panelSubtitle)
                            .foregroundStyle(RadarTheme.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(RadarTheme.Spacing.card)
                }
            } else {
                MonitorFrame {
                    PanelRowStack(monitorStore.watchlistQuotes) { quote in
                        MarketWatchlistRowView(
                            quote: quote,
                            metric: monitorStore.metric(for: quote),
                            absoluteChange: monitorStore.dayAbsoluteChange(for: quote),
                            percentageChange: quote.changePercentage,
                            sparklinePoints: monitorStore.sparklinePoints(for: quote),
                            updatedAt: monitorStore.updatedAt(for: quote),
                            statusStyle: monitorStore.marketTagStyle(for: quote),
                            isSelected: monitorStore.selectedQuoteID == quote.id,
                            isTracked: monitorStore.isInWatchlist(quote),
                            onSelect: {
                                monitorStore.selectQuote(quote)
                            },
                            onToggleWatchlist: {
                                monitorStore.toggleWatchlist(quote)
                            }
                        )
                    }
                }
            }
        }
    }

    private var quotesPanel: some View {
        DashboardPanel(
            title: "Market Tape",
            subtitle: "Flujo comprimido de cotizaciones y tasas destacadas",
            metadataItems: [
                PanelMetadataItem(title: "Rows", value: "\(monitorStore.quoteRows.count)"),
                PanelMetadataItem.updated(overviewUpdatedText)
            ],
            badges: [
                PanelBadge("LIVE", style: .live),
                PanelBadge("TAPE", style: .neutral)
            ]
        ) {
            MonitorFrame {
                PanelRowStack(monitorStore.quoteRows) { quote in
                    MarketMonitorRow(
                        quote: quote,
                        metric: monitorStore.metric(for: quote),
                        absoluteChange: monitorStore.dayAbsoluteChange(for: quote),
                        percentageChange: quote.changePercentage,
                        sparklinePoints: monitorStore.sparklinePoints(for: quote),
                        updatedAt: monitorStore.updatedAt(for: quote),
                        statusStyle: monitorStore.marketTagStyle(for: quote),
                        isSelected: monitorStore.selectedQuoteID == quote.id,
                        onSelect: {
                            monitorStore.selectQuote(quote)
                        }
                    ) {
                        MarketWatchToggleView(
                            isTracked: monitorStore.isInWatchlist(quote),
                            onToggle: {
                                monitorStore.toggleWatchlist(quote)
                            }
                        )
                    }
                }
            }
        }
    }

    private var variablesPanel: some View {
        DashboardPanel(
            title: "Macro Tape",
            subtitle: "Variables monetarias, de liquidez y contexto",
            metadataItems: [
                PanelMetadataItem(title: "Rows", value: "\(monitorStore.variableRows.count)"),
                PanelMetadataItem.updated(overviewUpdatedText)
            ],
            badges: []
        ) {
            MonitorFrame {
                PanelRowStack(monitorStore.variableRows) { indicator in
                    MarketIndicatorRowView(
                        indicator: indicator,
                        metric: monitorStore.metric(for: indicator)
                    )
                }
            }
        }
    }
}

@MainActor
private struct HomePreviewScene: View {
    @State private var store = MarketFixturesPreview.previewStore()

    var body: some View {
        NavigationStack {
            HomeView(monitorStore: store)
        }
    }
}

#Preview("Home Market Monitor") {
    HomePreviewScene()
}
