import SwiftUI

struct HomeView: View {
    let monitorStore: MarketStore
    @State private var expandedOverviewTileID: String?

    private let compactOverviewTileHeight: CGFloat = 134
    private let expandedOverviewTileHeight: CGFloat = 186

    private enum OverviewGridRow: Identifiable {
        case expanded(MarketQuote)
        case pair(MarketQuote, MarketQuote?)

        var id: String {
            switch self {
            case let .expanded(quote):
                return "expanded-\(quote.id)"
            case let .pair(left, right):
                return "pair-\(left.id)-\(right?.id ?? "empty")"
            }
        }
    }

    init(monitorStore: MarketStore) {
        self.monitorStore = monitorStore
    }

    private var overviewUpdatedText: String {
        guard let updatedAt = monitorStore.overviewUpdatedAt else {
            return "Sin dato"
        }

        return RadarFormatters.timestamp(updatedAt)
    }

    private var overviewGridRows: [OverviewGridRow] {
        let pairs = stride(from: 0, to: monitorStore.overviewTiles.count, by: 2).map { index in
            Array(monitorStore.overviewTiles[index..<min(index + 2, monitorStore.overviewTiles.count)])
        }

        let orderedQuotes = pairs.flatMap { pair -> [MarketQuote] in
            guard
                let expandedOverviewTileID,
                let expandedIndex = pair.firstIndex(where: { $0.id == expandedOverviewTileID })
            else {
                return pair
            }

            var reorderedPair = pair
            let expandedQuote = reorderedPair.remove(at: expandedIndex)
            reorderedPair.insert(expandedQuote, at: 0)
            return reorderedPair
        }

        var rows: [OverviewGridRow] = []
        var pendingQuotes: [MarketQuote] = []

        for quote in orderedQuotes {
            if quote.id == expandedOverviewTileID {
                if let firstPending = pendingQuotes.first {
                    rows.append(.pair(firstPending, pendingQuotes.count > 1 ? pendingQuotes[1] : nil))
                    pendingQuotes.removeAll()
                }

                rows.append(.expanded(quote))
            } else {
                pendingQuotes.append(quote)

                if pendingQuotes.count == 2 {
                    rows.append(.pair(pendingQuotes[0], pendingQuotes[1]))
                    pendingQuotes.removeAll()
                }
            }
        }

        if let firstPending = pendingQuotes.first {
            rows.append(.pair(firstPending, pendingQuotes.count > 1 ? pendingQuotes[1] : nil))
        }

        return rows
    }

    var body: some View {
        ZStack {
            TerminalScreenBackground()

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: RadarTheme.Spacing.section) {
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
            title: "Monitor principal",
            subtitle: "radAR · monitoreo de mercado BCRA",
            metadataItems: [
                PanelMetadataItem(title: "Universo", value: "\(monitorStore.quoteRows.count)"),
                PanelMetadataItem(title: "Siguiendo", value: "\(monitorStore.watchlistCount)"),
                PanelMetadataItem.updated(overviewUpdatedText)
            ],
            badges: [
                PanelBadge("LIVE", style: .live),
                PanelBadge("BCRA", style: .category),
                PanelBadge("MONITOR", style: .neutral)
            ]
        ) {
            Grid(
                alignment: .leading,
                horizontalSpacing: RadarTheme.Spacing.compact,
                verticalSpacing: RadarTheme.Spacing.compact
            ) {
                ForEach(overviewGridRows) { row in
                    switch row {
                    case let .expanded(quote):
                        overviewTile(quote, expanded: true)
                            .frame(
                                maxWidth: .infinity,
                                minHeight: expandedOverviewTileHeight,
                                maxHeight: expandedOverviewTileHeight,
                                alignment: .leading
                            )
                            .gridCellColumns(2)

                    case let .pair(leftQuote, rightQuote):
                        GridRow {
                            overviewTile(leftQuote, expanded: false)
                                .frame(
                                    maxWidth: .infinity,
                                    minHeight: compactOverviewTileHeight,
                                    maxHeight: compactOverviewTileHeight,
                                    alignment: .leading
                                )

                            if let rightQuote {
                                overviewTile(rightQuote, expanded: false)
                                    .frame(
                                        maxWidth: .infinity,
                                        minHeight: compactOverviewTileHeight,
                                        maxHeight: compactOverviewTileHeight,
                                        alignment: .leading
                                    )
                            } else {
                                Color.clear
                                    .frame(maxWidth: .infinity, minHeight: compactOverviewTileHeight, maxHeight: compactOverviewTileHeight)
                                    .hidden()
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(.snappy(duration: 0.32, extraBounce: 0.08), value: expandedOverviewTileID)
        }
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

    @ViewBuilder
    private var detailPanel: some View {
        if let quote = monitorStore.selectedQuote, let metric = monitorStore.selectedMetric {
            @Bindable var monitorStore = monitorStore

            DashboardPanel(
                title: "Monitor expandido",
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
                PanelMetadataItem(title: "Siguiendo", value: "\(monitorStore.watchlistCount)"),
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
            title: "Tasas y FX",
            subtitle: "Flujo comprimido de cotizaciones y tasas destacadas",
            metadataItems: [
                PanelMetadataItem(title: "Filas", value: "\(monitorStore.quoteRows.count)"),
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
            title: "Monitor Macro",
            subtitle: "Variables monetarias, de liquidez y contexto",
            metadataItems: [
                PanelMetadataItem(title: "Filas", value: "\(monitorStore.variableRows.count)"),
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
