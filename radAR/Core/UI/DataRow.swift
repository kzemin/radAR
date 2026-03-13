import SwiftUI

struct DataRow<TrailingContent: View>: View {
    let title: String
    var subtitle: String?
    var leadingTag: String?
    var leadingTagStyle: StatusChipStyle = .neutral
    var metric: FinancialMetric?
    var absoluteChange: FinancialChange?
    var percentageChange: Double?
    var sparklinePoints: [MarketPoint] = []
    var sparklineTrend: Double?
    var compactNumbers = false
    var isHighlighted = false
    private let trailingContent: TrailingContent

    init(
        title: String,
        subtitle: String? = nil,
        leadingTag: String? = nil,
        leadingTagStyle: StatusChipStyle = .neutral,
        metric: FinancialMetric? = nil,
        absoluteChange: FinancialChange? = nil,
        percentageChange: Double? = nil,
        sparklinePoints: [MarketPoint] = [],
        sparklineTrend: Double? = nil,
        compactNumbers: Bool = false,
        isHighlighted: Bool = false,
        @ViewBuilder trailingContent: () -> TrailingContent
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leadingTag = leadingTag
        self.leadingTagStyle = leadingTagStyle
        self.metric = metric
        self.absoluteChange = absoluteChange
        self.percentageChange = percentageChange
        self.sparklinePoints = sparklinePoints
        self.sparklineTrend = sparklineTrend
        self.compactNumbers = compactNumbers
        self.isHighlighted = isHighlighted
        self.trailingContent = trailingContent()
    }

    private var showsInlineValue: Bool {
        metric != nil || !sparklinePoints.isEmpty || absoluteChange != nil || percentageChange != nil
    }

    var body: some View {
        HStack(spacing: RadarTheme.Spacing.row) {
            VStack(alignment: .leading, spacing: RadarTheme.Spacing.micro) {
                HStack(spacing: RadarTheme.Spacing.small) {
                    Text(title)
                        .font(RadarTheme.Typography.rowLabel)
                        .foregroundStyle(RadarTheme.Colors.textPrimary)

                    if let leadingTag {
                        StatusChip(title: leadingTag, style: leadingTagStyle)
                    }
                }

                if let subtitle {
                    Text(subtitle)
                        .font(RadarTheme.Typography.rowSecondary)
                        .foregroundStyle(RadarTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: RadarTheme.Spacing.row)

            if showsInlineValue {
                HStack(spacing: RadarTheme.Spacing.row) {
                    if !sparklinePoints.isEmpty {
                        MiniSparkline(
                            points: sparklinePoints,
                            trend: sparklineTrend ?? percentageChange ?? absoluteChange?.value
                        )
                        .frame(width: 64, height: 22)
                    }

                    if let metric {
                        FinancialValue(
                            metric: metric,
                            absoluteChange: absoluteChange,
                            percentageChange: percentageChange,
                            compactNumbers: compactNumbers,
                            alignment: .trailing,
                            valueFont: RadarTheme.Typography.compactLabel
                        )
                        .frame(width: 118, alignment: .trailing)
                    }
                }
            }

            trailingContent
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(
            Rectangle()
                .fill(isHighlighted ? RadarTheme.Colors.accent.opacity(0.05) : .clear)
        )
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(isHighlighted ? RadarTheme.Colors.accent : .clear)
                .frame(width: isHighlighted ? 2 : 0)
        }
    }
}

extension DataRow where TrailingContent == EmptyView {
    init(
        title: String,
        subtitle: String? = nil,
        leadingTag: String? = nil,
        leadingTagStyle: StatusChipStyle = .neutral,
        metric: FinancialMetric? = nil,
        absoluteChange: FinancialChange? = nil,
        percentageChange: Double? = nil,
        sparklinePoints: [MarketPoint] = [],
        sparklineTrend: Double? = nil,
        compactNumbers: Bool = false,
        isHighlighted: Bool = false
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            leadingTag: leadingTag,
            leadingTagStyle: leadingTagStyle,
            metric: metric,
            absoluteChange: absoluteChange,
            percentageChange: percentageChange,
            sparklinePoints: sparklinePoints,
            sparklineTrend: sparklineTrend,
            compactNumbers: compactNumbers,
            isHighlighted: isHighlighted
        ) {
            EmptyView()
        }
    }
}

#Preview("Data Row") {
    PanelContainer {
        DataRow(
            title: "USD MEP",
            subtitle: "Bonos soberanos",
            leadingTag: "live",
            leadingTagStyle: .live,
            metric: FinancialMetric(value: 1124.8, format: .currency(code: "ARS")),
            absoluteChange: FinancialChange(value: 8.2, format: .currency(code: "ARS")),
            percentageChange: 0.8,
            sparklinePoints: DataRowPreview.points,
            sparklineTrend: 0.8,
            isHighlighted: true
            )
    }
    .padding()
    .background(TerminalScreenBackground())
}

private enum DataRowPreview {
    static let points: [MarketPoint] = (0..<18).map { index in
        MarketPoint(
            id: "row-\(index)",
            date: Calendar.current.date(byAdding: .day, value: -(18 - index), to: .now) ?? .now,
            value: 100 + Double(index) + sin(Double(index) / 3.1) * 2.8
        )
    }
}
