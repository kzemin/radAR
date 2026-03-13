import SwiftUI

struct PanelHeaderAction: Identifiable {
    let id: String
    let systemImage: String
    let accessibilityLabel: String
    var tint: Color = RadarTheme.Colors.textSecondary
    let action: () -> Void

    init(
        id: String? = nil,
        systemImage: String,
        accessibilityLabel: String,
        tint: Color = RadarTheme.Colors.textSecondary,
        action: @escaping () -> Void
    ) {
        self.id = id ?? systemImage
        self.systemImage = systemImage
        self.accessibilityLabel = accessibilityLabel
        self.tint = tint
        self.action = action
    }
}

struct PanelHeader<TrailingContent: View>: View {
    let title: String
    let subtitle: String?
    var statusTitle: String?
    var statusStyle: StatusChipStyle = .neutral
    var metadata: [PanelMetadataItem] = []
    var actions: [PanelHeaderAction] = []
    private let trailingContent: TrailingContent

    init(
        title: String,
        subtitle: String? = nil,
        statusTitle: String? = nil,
        statusStyle: StatusChipStyle = .neutral,
        metadata: [PanelMetadataItem] = [],
        actions: [PanelHeaderAction] = [],
        @ViewBuilder trailingContent: () -> TrailingContent
    ) {
        self.title = title
        self.subtitle = subtitle
        self.statusTitle = statusTitle
        self.statusStyle = statusStyle
        self.metadata = metadata
        self.actions = actions
        self.trailingContent = trailingContent()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: RadarTheme.Spacing.micro) {
            HStack(alignment: .top, spacing: RadarTheme.Spacing.row) {
                VStack(alignment: .leading, spacing: RadarTheme.Spacing.micro) {
                    HStack(spacing: RadarTheme.Spacing.small) {
                        Text(title.uppercased())
                            .font(RadarTheme.Typography.panelTitle)
                            .tracking(0.8)
                            .foregroundStyle(RadarTheme.Colors.textPrimary)

                        if let statusTitle {
                            StatusChip(title: statusTitle, style: statusStyle)
                        }
                    }

                    if let subtitle {
                        Text(subtitle)
                            .font(RadarTheme.Typography.panelSubtitle)
                            .foregroundStyle(RadarTheme.Colors.textSecondary)
                            .lineLimit(2)
                    }
                }

                Spacer(minLength: RadarTheme.Spacing.row)

                HStack(spacing: RadarTheme.Spacing.xSmall) {
                    ForEach(actions) { action in
                        PanelHeaderIconButton(action: action)
                    }

                    trailingContent
                }
            }

            if !metadata.isEmpty {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: RadarTheme.Spacing.row) {
                        ForEach(metadata) { item in
                            PanelTimestamp(title: item.title, value: item.value)
                        }
                    }

                    VStack(alignment: .leading, spacing: RadarTheme.Spacing.small) {
                        ForEach(metadata) { item in
                            PanelTimestamp(title: item.title, value: item.value)
                        }
                    }
                }
            }
        }
    }
}

extension PanelHeader where TrailingContent == EmptyView {
    init(
        title: String,
        subtitle: String? = nil,
        statusTitle: String? = nil,
        statusStyle: StatusChipStyle = .neutral,
        metadata: [PanelMetadataItem] = [],
        actions: [PanelHeaderAction] = []
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            statusTitle: statusTitle,
            statusStyle: statusStyle,
            metadata: metadata,
            actions: actions
        ) {
            EmptyView()
        }
    }
}

private struct PanelHeaderIconButton: View {
    let action: PanelHeaderAction

    var body: some View {
        Button(action: action.action) {
            Image(systemName: action.systemImage)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(action.tint)
                .frame(width: 26, height: 22)
                .background(
                    Rectangle()
                        .fill(RadarTheme.Colors.surfaceMuted)
                )
                .overlay(
                    Rectangle()
                        .stroke(RadarTheme.Colors.separator, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(action.accessibilityLabel)
    }
}

struct DenseSectionHeader: View {
    let title: String
    let subtitle: String?
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        title: String,
        subtitle: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        PanelHeader(title: title, subtitle: subtitle) {
            if let actionTitle, let action {
                TerminalButton(
                    title: actionTitle,
                    style: .secondary,
                    action: action
                )
            }
        }
    }
}

struct SectionHeader: View {
    let title: String
    let subtitle: String?
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        title: String,
        subtitle: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        DenseSectionHeader(
            title: title,
            subtitle: subtitle,
            actionTitle: actionTitle,
            action: action
        )
    }
}

#Preview("Dense Section Header") {
    PanelContainer(style: .secondary) {
        DenseSectionHeader(
            title: "Market Summary",
            subtitle: "Lectura rápida del contexto local",
            actionTitle: "Open Market",
            action: {}
        )
    }
    .padding()
    .background(TerminalScreenBackground())
}

#Preview("Panel Header") {
    PanelContainer(style: .secondary) {
        PanelHeader(
            title: "USD Monitor",
            subtitle: "Panel compacto",
            statusTitle: "LIVE",
            statusStyle: .live,
            metadata: [
                .updated("12 Mar 11:42"),
                PanelMetadataItem(title: "Source", value: "BCRA")
            ],
            actions: [
                PanelHeaderAction(
                    systemImage: "arrow.clockwise",
                    accessibilityLabel: "Refresh",
                    tint: RadarTheme.Colors.accent,
                    action: {}
                ),
                PanelHeaderAction(
                    systemImage: "slider.horizontal.3",
                    accessibilityLabel: "Filter",
                    action: {}
                )
            ]
        )
    }
    .padding()
    .background(TerminalScreenBackground())
}
