import SwiftUI

struct FinancialValue: View {
    let metric: FinancialMetric
    var secondaryLabel: String?
    var absoluteChange: FinancialChange?
    var percentageChange: Double?
    var compactNumbers = false
    var alignment: HorizontalAlignment = .leading
    var valueFont: Font = RadarTheme.Typography.value

    init(
        metric: FinancialMetric,
        secondaryLabel: String? = nil,
        absoluteChange: FinancialChange? = nil,
        percentageChange: Double? = nil,
        compactNumbers: Bool = false,
        alignment: HorizontalAlignment = .leading,
        valueFont: Font = RadarTheme.Typography.value
    ) {
        self.metric = metric
        self.secondaryLabel = secondaryLabel
        self.absoluteChange = absoluteChange
        self.percentageChange = percentageChange
        self.compactNumbers = compactNumbers
        self.alignment = alignment
        self.valueFont = valueFont
    }

    init(
        metric: FinancialMetric,
        secondaryLabel: String? = nil,
        change: FinancialChange? = nil,
        compactNumbers: Bool = false,
        alignment: HorizontalAlignment = .leading,
        valueFont: Font = RadarTheme.Typography.value
    ) {
        let resolvedAbsoluteChange: FinancialChange?
        let resolvedPercentageChange: Double?

        if let change {
            switch change.format {
            case .percentage:
                resolvedAbsoluteChange = nil
                resolvedPercentageChange = change.value
            default:
                resolvedAbsoluteChange = change
                resolvedPercentageChange = nil
            }
        } else {
            resolvedAbsoluteChange = nil
            resolvedPercentageChange = nil
        }

        self.init(
            metric: metric,
            secondaryLabel: secondaryLabel,
            absoluteChange: resolvedAbsoluteChange,
            percentageChange: resolvedPercentageChange,
            compactNumbers: compactNumbers,
            alignment: alignment,
            valueFont: valueFont
        )
    }

    init(
        metric: FinancialMetric,
        detail: String? = nil,
        change: Double?,
        compactNumbers: Bool = false,
        alignment: HorizontalAlignment = .leading,
        valueFont: Font = RadarTheme.Typography.value
    ) {
        self.init(
            metric: metric,
            secondaryLabel: detail,
            percentageChange: change,
            compactNumbers: compactNumbers,
            alignment: alignment,
            valueFont: valueFont
        )
    }

    private var formattedValue: String {
        RadarFormatters.metric(metric, compact: compactNumbers)
    }

    private var trendValue: Double? {
        percentageChange ?? absoluteChange?.value
    }

    private var changeColor: Color {
        guard let trendValue else {
            return RadarTheme.Colors.textSecondary
        }

        if trendValue > 0 { return RadarTheme.Colors.positive }
        if trendValue < 0 { return RadarTheme.Colors.negative }
        return RadarTheme.Colors.textSecondary
    }

    private var absoluteChangeText: String? {
        absoluteChange.map { RadarFormatters.change($0, compact: compactNumbers) }
    }

    private var percentageChangeText: String? {
        guard let percentageChange else {
            return nil
        }

        return RadarFormatters.signedRate(percentageChange)
    }

    var body: some View {
        VStack(alignment: alignment, spacing: RadarTheme.Spacing.micro) {
            Text(formattedValue)
                .font(valueFont)
                .foregroundStyle(RadarTheme.Colors.textPrimary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            if secondaryLabel != nil || absoluteChangeText != nil || percentageChangeText != nil {
                HStack(spacing: RadarTheme.Spacing.small) {
                    if let secondaryLabel {
                        Text(secondaryLabel)
                            .font(RadarTheme.Typography.panelSubtitle)
                            .foregroundStyle(RadarTheme.Colors.textSecondary)
                            .lineLimit(1)
                    }

                    let hasChange = absoluteChangeText != nil || percentageChangeText != nil

                    if secondaryLabel != nil && hasChange {
                        Spacer(minLength: RadarTheme.Spacing.small)
                    }

                    if let absoluteChangeText {
                        Text(absoluteChangeText)
                            .font(RadarTheme.Typography.compactLabel)
                            .foregroundStyle(changeColor)
                            .lineLimit(1)
                            .monospacedDigit()
                    }

                    if absoluteChangeText != nil && percentageChangeText != nil {
                        Text("|")
                            .font(RadarTheme.Typography.compactTag)
                            .foregroundStyle(RadarTheme.Colors.textTertiary)
                    }

                    if let percentageChangeText {
                        Text(percentageChangeText)
                            .font(RadarTheme.Typography.compactLabel)
                            .foregroundStyle(changeColor)
                            .lineLimit(1)
                            .monospacedDigit()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .trailing)
    }
}

#Preview("Financial Value") {
    PanelContainer {
        HStack(spacing: 24) {
            FinancialValue(
                metric: FinancialMetric(value: 1_124.8, format: .currency(code: "ARS")),
                secondaryLabel: "USD MEP",
                absoluteChange: FinancialChange(value: 8.4, format: .currency(code: "ARS")),
                percentageChange: 0.8,
                valueFont: RadarTheme.Typography.largeValue
            )

            FinancialValue(
                metric: FinancialMetric(value: 31.5, format: .percentage),
                secondaryLabel: "TNA",
                percentageChange: -0.4,
                alignment: .trailing,
                valueFont: RadarTheme.Typography.largeValue
            )
        }
    }
    .padding()
    .background(TerminalScreenBackground())
}
