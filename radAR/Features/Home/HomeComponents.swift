import SwiftUI

private func homeCategoryTag(for category: ProductCategory) -> String {
    switch category {
    case .savingsAccount:
        return "CAJA"
    case .package:
        return "PACK"
    case .termDeposit:
        return "PF"
    case .personalLoan:
        return "LOAN"
    case .creditCard:
        return "TC"
    }
}

struct HomeMonitorStatView: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: RadarTheme.Spacing.micro) {
            Text(title.uppercased())
                .font(RadarTheme.Typography.compactTag)
                .tracking(0.6)
                .foregroundStyle(RadarTheme.Colors.textSecondary)

            Text(value)
                .font(RadarTheme.Typography.largeValue)
                .foregroundStyle(RadarTheme.Colors.textPrimary)
                .monospacedDigit()
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct HomeMacroTileView: View {
    let item: HomeMacroMetric
    let compactNumbers: Bool

    private var statusStyle: StatusChipStyle {
        switch item.badge?.uppercased() {
        case "FX":
            return .live
        case "MACRO":
            return .category
        case "RATE":
            return .warning
        default:
            return .neutral
        }
    }

    var body: some View {
        PanelContainer(style: .inset) {
            VStack(alignment: .leading, spacing: RadarTheme.Spacing.small) {
                HStack(spacing: RadarTheme.Spacing.small) {
                    Text(item.title)
                        .font(RadarTheme.Typography.compactLabel)
                        .foregroundStyle(RadarTheme.Colors.textPrimary)
                        .lineLimit(1)

                    if let badge = item.badge {
                        StatusChip(title: badge, style: statusStyle)
                    }
                }

                Text(item.subtitle)
                    .font(RadarTheme.Typography.panelSubtitle)
                    .foregroundStyle(RadarTheme.Colors.textSecondary)
                    .lineLimit(2)

                FinancialValue(
                    metric: item.metric,
                    percentageChange: item.changePercentage,
                    compactNumbers: compactNumbers,
                    valueFont: RadarTheme.Typography.value
                )

                if !item.points.isEmpty {
                    MiniSparkline(
                        points: item.points,
                        trend: item.changePercentage,
                        showsArea: true
                    )
                    .frame(height: 30)
                }
            }
        }
    }
}

struct HomeMarketLineRowView: View {
    enum Style {
        case watchlist
        case mover
    }

    let item: HomeMarketLine
    let compactNumbers: Bool
    var style: Style = .watchlist

    private var tagTitle: String {
        switch style {
        case .watchlist:
            return item.market.uppercased()
        case .mover:
            return item.changePercentage >= 0 ? "UP" : "DOWN"
        }
    }

    private var tagStyle: StatusChipStyle {
        switch style {
        case .watchlist:
            return item.market.lowercased() == "tasas" ? .warning : .category
        case .mover:
            return item.changePercentage >= 0 ? .positive : .negative
        }
    }

    var body: some View {
        DataRow(
            title: item.symbol,
            subtitle: item.name,
            leadingTag: tagTitle,
            leadingTagStyle: tagStyle,
            metric: item.metric,
            percentageChange: item.changePercentage,
            sparklinePoints: item.points,
            sparklineTrend: item.changePercentage,
            compactNumbers: compactNumbers,
            isHighlighted: style == .mover
        ) {
            Text(RadarFormatters.shortTime(item.updatedAt))
                .font(RadarTheme.Typography.compactTag)
                .foregroundStyle(RadarTheme.Colors.textTertiary)
                .frame(width: 44, alignment: .trailing)
        }
    }
}

struct HomeQuickCompareRowView: View {
    let action: HomeQuickAction
    let compactNumbers: Bool
    let perform: (ProductCategory) -> Void

    var body: some View {
        Button {
            perform(action.category)
        } label: {
            DataRow(
                title: action.title,
                subtitle: action.subtitle,
                leadingTag: homeCategoryTag(for: action.category),
                leadingTagStyle: .category,
                metric: action.metric,
                compactNumbers: compactNumbers
            ) {
                HStack(spacing: RadarTheme.Spacing.small) {
                    Text(action.detail.uppercased())
                        .font(RadarTheme.Typography.compactTag)
                        .foregroundStyle(RadarTheme.Colors.textSecondary)

                    Image(systemName: "chevron.right")
                        .font(RadarTheme.Typography.compactLabel)
                        .foregroundStyle(RadarTheme.Colors.textSecondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct HomeFeaturedProductRowView: View {
    let item: HomeFeaturedProduct
    let compactNumbers: Bool
    let perform: (ProductCategory) -> Void

    var body: some View {
        Button {
            perform(item.category)
        } label: {
            DataRow(
                title: item.title,
                subtitle: item.institution,
                leadingTag: homeCategoryTag(for: item.category),
                leadingTagStyle: .warning
            ) {
                VStack(alignment: .trailing, spacing: RadarTheme.Spacing.micro) {
                    Text(item.label.uppercased())
                        .font(RadarTheme.Typography.compactTag)
                        .foregroundStyle(RadarTheme.Colors.textSecondary)

                    Text(RadarFormatters.metric(item.primaryMetric, compact: compactNumbers))
                        .font(RadarTheme.Typography.compactLabel)
                        .foregroundStyle(RadarTheme.Colors.textPrimary)
                        .monospacedDigit()

                    if let secondaryMetric = item.secondaryMetric {
                        Text(RadarFormatters.metric(secondaryMetric, compact: compactNumbers))
                            .font(RadarTheme.Typography.compactTag)
                            .foregroundStyle(RadarTheme.Colors.textSecondary)
                            .monospacedDigit()
                    }

                    Text(RadarFormatters.shortDate(item.updatedAt))
                        .font(RadarTheme.Typography.compactTag)
                        .foregroundStyle(RadarTheme.Colors.textTertiary)
                }
                .frame(width: 104, alignment: .trailing)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview("Monitor Stat") {
    HomeMonitorStatView(title: "Watchlist", value: "05")
        .padding()
        .background(TerminalScreenBackground())
}

#Preview("Macro Tile") {
    HomeMacroTileView(
        item: HomeFixtures.dashboard.macroSummary[0],
        compactNumbers: true
    )
    .padding()
    .background(TerminalScreenBackground())
}

#Preview("Watchlist Row") {
    DashboardPanel(title: "Watchlist") {
        HomeMarketLineRowView(
            item: HomeFixtures.dashboard.watchlist[0],
            compactNumbers: true
        )
    }
    .padding()
    .background(TerminalScreenBackground())
}

#Preview("Featured Product Row") {
    DashboardPanel(title: "Featured") {
        HomeFeaturedProductRowView(
            item: HomeFixtures.dashboard.featuredProducts[0],
            compactNumbers: true,
            perform: { _ in }
        )
    }
    .padding()
    .background(TerminalScreenBackground())
}
