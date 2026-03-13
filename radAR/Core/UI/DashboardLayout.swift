import SwiftUI

struct PanelBadge: Identifiable, Hashable {
    let id: String
    let title: String
    let style: StatusChipStyle

    init(
        _ title: String,
        style: StatusChipStyle = .neutral,
        id: String? = nil
    ) {
        self.id = id ?? "\(title)-\(style)"
        self.title = title
        self.style = style
    }
}

struct PanelMetadataItem: Identifiable, Hashable {
    let id: String
    let title: String
    let value: String

    init(
        id: String? = nil,
        title: String,
        value: String
    ) {
        self.id = id ?? "\(title)-\(value)"
        self.title = title
        self.value = value
    }

    static func updated(_ value: String) -> PanelMetadataItem {
        PanelMetadataItem(title: "Actualizado", value: value)
    }
}

struct PanelTimestamp: View {
    let title: String
    let value: String

    init(
        title: String = "Actualizado",
        value: String
    ) {
        self.title = title
        self.value = value
    }

    var body: some View {
        HStack(spacing: RadarTheme.Spacing.xSmall) {
            Text(title.uppercased())
                .font(RadarTheme.Typography.compactTag)
                .tracking(0.7)
                .foregroundStyle(RadarTheme.Colors.textTertiary)

            Text(value.uppercased())
                .font(RadarTheme.Typography.compactLabel)
                .foregroundStyle(RadarTheme.Colors.textSecondary)
        }
    }
}

struct PanelMetadataBar: View {
    var items: [PanelMetadataItem] = []
    var badges: [PanelBadge] = []

    var body: some View {
        if !items.isEmpty || !badges.isEmpty {
            ViewThatFits(in: .horizontal) {
                horizontalLayout
                verticalLayout
            }
        }
    }

    private var horizontalLayout: some View {
        HStack(alignment: .center, spacing: RadarTheme.Spacing.row) {
            metadataItems

            Spacer(minLength: RadarTheme.Spacing.row)

            badgeRow
        }
        .padding(.bottom, 2)
    }

    private var verticalLayout: some View {
        VStack(alignment: .leading, spacing: RadarTheme.Spacing.small) {
            metadataItems
            badgeRow
        }
        .padding(.bottom, 2)
    }

    private var metadataItems: some View {
        HStack(spacing: RadarTheme.Spacing.row) {
            ForEach(items) { item in
                PanelTimestamp(title: item.title, value: item.value)
            }
        }
    }

    private var badgeRow: some View {
        HStack(spacing: RadarTheme.Spacing.xSmall) {
            ForEach(badges) { badge in
                StatusChip(title: badge.title, style: badge.style)
            }
        }
    }
}

struct DashboardPanel<TrailingContent: View, Content: View>: View {
    let title: String
    var subtitle: String?
    var style: PanelContainerStyle = .primary
    var metadataItems: [PanelMetadataItem] = []
    var badges: [PanelBadge] = []

    private let trailingContent: TrailingContent
    private let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        style: PanelContainerStyle = .primary,
        metadataItems: [PanelMetadataItem] = [],
        badges: [PanelBadge] = [],
        @ViewBuilder trailingContent: () -> TrailingContent,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.style = style
        self.metadataItems = metadataItems
        self.badges = badges
        self.trailingContent = trailingContent()
        self.content = content()
    }

    var body: some View {
        PanelContainer(style: style) {
            VStack(alignment: .leading, spacing: RadarTheme.Spacing.compact) {
                PanelHeader(title: title, subtitle: subtitle) {
                    trailingContent
                }

                if !metadataItems.isEmpty || !badges.isEmpty {
                    PanelMetadataBar(
                        items: metadataItems,
                        badges: badges
                    )
                }

                content
            }
        }
    }
}

extension DashboardPanel where TrailingContent == EmptyView {
    init(
        title: String,
        subtitle: String? = nil,
        style: PanelContainerStyle = .primary,
        metadataItems: [PanelMetadataItem] = [],
        badges: [PanelBadge] = [],
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            style: style,
            metadataItems: metadataItems,
            badges: badges,
            trailingContent: { EmptyView() },
            content: content
        )
    }
}

struct DashboardGrid<Content: View>: View {
    private let columns: [GridItem]
    private let spacing: CGFloat
    private let content: Content

    init(
        columnCount: Int = 2,
        spacing: CGFloat = RadarTheme.Spacing.compact,
        @ViewBuilder content: () -> Content
    ) {
        let resolvedCount = max(1, columnCount)
        self.columns = Array(
            repeating: GridItem(.flexible(), spacing: spacing, alignment: .top),
            count: resolvedCount
        )
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: spacing) {
            content
        }
    }
}

struct PanelDivider: View {
    var body: some View {
        Rectangle()
            .fill(RadarTheme.Colors.separator)
            .frame(height: 1)
    }
}

struct PanelRowStack<Data: RandomAccessCollection, RowContent: View>: View where Data.Element: Identifiable {
    private let items: [Data.Element]
    private let showsDividers: Bool
    private let rowContent: (Data.Element) -> RowContent

    init(
        _ items: Data,
        showsDividers: Bool = true,
        @ViewBuilder rowContent: @escaping (Data.Element) -> RowContent
    ) {
        self.items = Array(items)
        self.showsDividers = showsDividers
        self.rowContent = rowContent
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                rowContent(item)

                if showsDividers && index < items.count - 1 {
                    PanelDivider()
                }
            }
        }
    }
}

struct PanelGroup<TrailingContent: View, Content: View>: View {
    var title: String?
    var subtitle: String?

    private let trailingContent: TrailingContent
    private let content: Content

    init(
        title: String? = nil,
        subtitle: String? = nil,
        @ViewBuilder trailingContent: () -> TrailingContent,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.trailingContent = trailingContent()
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: RadarTheme.Spacing.small) {
            if title != nil || subtitle != nil {
                HStack(alignment: .firstTextBaseline, spacing: RadarTheme.Spacing.row) {
                    VStack(alignment: .leading, spacing: RadarTheme.Spacing.micro) {
                        if let title {
                            Text(title.uppercased())
                                .font(RadarTheme.Typography.compactLabel)
                                .tracking(0.6)
                                .foregroundStyle(RadarTheme.Colors.textSecondary)
                        }

                        if let subtitle {
                            Text(subtitle)
                                .font(RadarTheme.Typography.rowSecondary)
                                .foregroundStyle(RadarTheme.Colors.textTertiary)
                        }
                    }

                    Spacer(minLength: RadarTheme.Spacing.row)

                    trailingContent
                }
            }

            content
        }
        .padding(.vertical, RadarTheme.Spacing.small)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension PanelGroup where TrailingContent == EmptyView {
    init(
        title: String? = nil,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            trailingContent: { EmptyView() },
            content: content
        )
    }
}

#Preview("Dashboard Layout") {
    ScrollView {
        VStack(alignment: .leading, spacing: RadarTheme.Spacing.section) {
            DashboardPanel(
                title: "Market Monitor",
                subtitle: "Resumen táctico",
                style: .elevated,
                metadataItems: [
                    .updated("12 Mar 10:48"),
                    PanelMetadataItem(title: "Source", value: "BCRA")
                ],
                badges: [
                    PanelBadge("Live", style: .accent),
                    PanelBadge("Alert", style: .warning)
                ]
            ) {
                DashboardGrid {
                    MetricBlock(
                        title: "USD MEP",
                        subtitle: "Bonos",
                        metric: FinancialMetric(value: 1_124.8, format: .currency(code: "ARS")),
                        change: FinancialChange(value: 0.8),
                        sparklinePoints: DashboardLayoutPreview.points,
                        style: .inset
                    )

                    MetricBlock(
                        title: "Badlar",
                        subtitle: "Tasa bancos privados",
                        metric: FinancialMetric(value: 31.2, format: .percentage),
                        change: FinancialChange(value: -0.2),
                        sparklinePoints: DashboardLayoutPreview.points,
                        style: .inset
                    )
                }

                PanelGroup(title: "Top movers", subtitle: "Seguimiento prioritario") {
                    PanelRowStack(DashboardLayoutPreview.rows) { item in
                        DataRow(
                            title: item.title,
                            subtitle: item.subtitle,
                            leadingTag: item.tag
                        ) {
                            HStack(spacing: RadarTheme.Spacing.row) {
                                MiniSparkline(
                                    points: DashboardLayoutPreview.points,
                                    trend: item.change
                                )
                                .frame(width: 72, height: 24)

                                FinancialValue(
                                    metric: FinancialMetric(
                                        value: item.value,
                                        format: .currency(code: "ARS")
                                    ),
                                    change: FinancialChange(value: item.change),
                                    alignment: .trailing,
                                    valueFont: RadarTheme.Typography.compactLabel
                                )
                                .frame(width: 110, alignment: .trailing)
                            }
                        }
                    }
                }
            }
        }
        .padding(RadarTheme.Spacing.screen)
    }
    .background(TerminalScreenBackground())
}

private enum DashboardLayoutPreview {
    struct Row: Identifiable {
        let id: String
        let title: String
        let subtitle: String
        let tag: String
        let value: Double
        let change: Double
    }

    static let rows: [Row] = [
        Row(id: "mep", title: "USD MEP", subtitle: "Bonos soberanos", tag: "live", value: 1_124.8, change: 0.8),
        Row(id: "ccl", title: "CCL", subtitle: "ADR / cable", tag: "alert", value: 1_142.6, change: -0.4)
    ]

    static let points: [MarketPoint] = (0..<24).map { index in
        MarketPoint(
            id: "dashboard-\(index)",
            date: Calendar.current.date(byAdding: .day, value: -(24 - index), to: .now) ?? .now,
            value: 100 + Double(index) + sin(Double(index) / 3.2) * 4
        )
    }
}
