import SwiftUI

enum PanelContainerStyle: Equatable {
    case primary
    case secondary
    case elevated
    case inset

    var backgroundColor: Color {
        switch self {
        case .primary, .secondary, .elevated:
            return RadarTheme.Colors.surface
        case .inset:
            return RadarTheme.Colors.backgroundElevated
        }
    }

    var padding: CGFloat {
        switch self {
        case .primary, .secondary, .elevated:
            return RadarTheme.Spacing.card
        case .inset:
            return RadarTheme.Spacing.compact
        }
    }
}

struct PanelContainer<Header: View, Content: View>: View {
    private let style: PanelContainerStyle
    private let spacing: CGFloat
    private let showsHeader: Bool
    private let header: Header
    private let content: Content

    init(
        style: PanelContainerStyle = .primary,
        spacing: CGFloat = RadarTheme.Spacing.compact,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.spacing = spacing
        self.showsHeader = true
        self.header = header()
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            if showsHeader {
                header
            }

            content
        }
        .padding(style.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(style.backgroundColor)
    }
}

extension PanelContainer where Header == EmptyView {
    init(
        style: PanelContainerStyle = .primary,
        spacing: CGFloat = RadarTheme.Spacing.compact,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.spacing = spacing
        self.showsHeader = false
        self.header = EmptyView()
        self.content = content()
    }
}

struct DashboardBlock<Content: View>: View {
    private let style: PanelContainerStyle
    private let content: Content

    init(
        style: PanelContainerStyle = .primary,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.content = content()
    }

    var body: some View {
        PanelContainer(style: style) {
            content
        }
    }
}

#Preview("Panel Container") {
    PanelContainer(
        style: .primary,
        header: {
            PanelHeader(
                title: "USD Monitor",
                statusTitle: "LIVE",
                statusStyle: .live,
                metadata: [
                    PanelMetadataItem.updated("12 Mar 11:20")
                ]
            )
        }
    ) {
        VStack(alignment: .leading, spacing: RadarTheme.Spacing.compact) {
            FinancialValue(
                metric: FinancialMetric(value: 1_124.2, format: .currency(code: "ARS")),
                secondaryLabel: "BONOS",
                percentageChange: 0.8,
                valueFont: RadarTheme.Typography.largeValue
            )
        }
    }
    .padding()
    .background(TerminalScreenBackground())
}
