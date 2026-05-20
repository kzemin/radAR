import Charts
import SwiftUI

struct MiniSparkline: View {
    let points: [MarketPoint]
    var trend: Double?
    var showsArea = false
    var lineWidth: CGFloat = 1.35
    var verticalPaddingRatio: Double = 0.18
    var minimumPaddingRatio: Double = 0.0035

    private var lineColor: Color {
        guard let trend else {
            return RadarTheme.Colors.accent
        }

        if trend > 0 {
            return RadarTheme.Colors.positive
        }

        if trend < 0 {
            return RadarTheme.Colors.negative
        }

        return RadarTheme.Colors.textSecondary
    }

    private var yDomain: ClosedRange<Double> {
        let values = points.map(\.value)
        guard let minValue = values.min(), let maxValue = values.max() else {
            return 0...1
        }

        let span = maxValue - minValue
        let padding = max(span * verticalPaddingRatio, max(abs(maxValue), 1) * minimumPaddingRatio)

        if span < 0.0001 {
            return (minValue - padding)...(maxValue + padding)
        }

        return (minValue - padding)...(maxValue + padding)
    }

    var body: some View {
        Chart(points) { point in
            LineMark(
                x: .value("Fecha", point.date),
                y: .value("Valor", point.value)
            )
            .interpolationMethod(.monotone)
            .lineStyle(.init(lineWidth: lineWidth))
            .foregroundStyle(lineColor)

            if showsArea {
                AreaMark(
                    x: .value("Fecha", point.date),
                    yStart: .value("Base", yDomain.lowerBound),
                    yEnd: .value("Valor", point.value)
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            lineColor.opacity(0.18),
                            lineColor.opacity(0.01)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .chartYScale(domain: yDomain)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .chartPlotStyle { plot in
            plot.background(Color.clear)
        }
        .accessibilityHidden(true)
    }
}

struct SparklineChart: View {
    let points: [MarketPoint]
    var trend: Double?
    var showsArea = false

    var body: some View {
        MiniSparkline(points: points, trend: trend, showsArea: showsArea)
    }
}

#Preview("Mini Sparkline") {
    MiniSparkline(
        points: SparklinePreviewData.points,
        trend: 0.9,
        showsArea: true
    )
    .frame(width: 120, height: 40)
    .padding()
    .background(TerminalScreenBackground())
}

private enum SparklinePreviewData {
    static let points: [MarketPoint] = (0..<20).map { index in
        let date = Calendar.current.date(byAdding: .day, value: -(20 - index), to: .now) ?? .now
        let seasonal = sin(Double(index) / 3.6) * 3.8
        let micro = cos(Double(index) / 2.1) * 1.1

        return MarketPoint(
            id: "preview-\(index)",
            date: date,
            value: 100 + (Double(index) * 0.7) + seasonal + micro
        )
    }
}
