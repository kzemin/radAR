import SwiftUI

struct MetricBlock: View {
    let title: String
    var subtitle: String?
    let metric: FinancialMetric
    var change: FinancialChange?
    var sparklinePoints: [MarketPoint] = []
    var compactNumbers = true
    var style: PanelContainerStyle = .secondary

    var body: some View {
        PanelContainer(style: style) {
            VStack(alignment: .leading, spacing: RadarTheme.Spacing.small) {
                Text(title.uppercased())
                    .font(RadarTheme.Typography.panelTitle)
                    .tracking(0.7)
                    .foregroundStyle(RadarTheme.Colors.textSecondary)

                HStack(alignment: .center, spacing: RadarTheme.Spacing.row) {
                    FinancialValue(
                        metric: metric,
                        secondaryLabel: subtitle?.uppercased(),
                        change: change,
                        compactNumbers: compactNumbers,
                        valueFont: RadarTheme.Typography.value
                    )

                    if !sparklinePoints.isEmpty {
                        MiniSparkline(
                            points: sparklinePoints,
                            trend: change?.value,
                            showsArea: true
                        )
                        .frame(width: 68, height: 28)
                    }
                }
            }
        }
    }
}

#Preview("Metric Block") {
    MetricBlock(
        title: "USD MEP",
        subtitle: "Bonos",
        metric: FinancialMetric(value: 1124.8, format: .currency(code: "ARS")),
        change: FinancialChange(value: 0.8),
        sparklinePoints: MetricBlockPreview.points
    )
    .padding()
    .background(TerminalScreenBackground())
}

private enum MetricBlockPreview {
    static let points: [MarketPoint] = (0..<18).map { index in
        MarketPoint(
            id: "metric-\(index)",
            date: Calendar.current.date(byAdding: .day, value: -(18 - index), to: .now) ?? .now,
            value: 100 + Double(index) + sin(Double(index) / 3) * 4
        )
    }
}
