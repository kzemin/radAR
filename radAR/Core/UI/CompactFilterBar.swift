import SwiftUI

struct DenseFilterBar<Content: View>: View {
    var title: String?
    var statusText: String?
    private let content: Content

    init(
        title: String? = nil,
        statusText: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.statusText = statusText
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: RadarTheme.Spacing.small) {
            if title != nil || statusText != nil {
                HStack(alignment: .firstTextBaseline, spacing: RadarTheme.Spacing.row) {
                    if let title {
                        Text(title.uppercased())
                            .font(RadarTheme.Typography.panelTitle)
                            .tracking(0.7)
                            .foregroundStyle(RadarTheme.Colors.textPrimary)
                    }

                    Spacer(minLength: RadarTheme.Spacing.row)

                    if let statusText {
                        Text(statusText.uppercased())
                            .font(RadarTheme.Typography.compactTag)
                            .foregroundStyle(RadarTheme.Colors.textSecondary)
                    }
                }
            }

            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct CompactFilterBar<Content: View>: View {
    var title: String?
    var statusText: String?
    private let content: Content

    init(
        title: String? = nil,
        statusText: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.statusText = statusText
        self.content = content()
    }

    var body: some View {
        DenseFilterBar(title: title, statusText: statusText) {
            content
        }
    }
}

#Preview("Dense Filter Bar") {
    DenseFilterBar(title: "Filters", statusText: "14 rows") {
        HStack(spacing: RadarTheme.Spacing.row) {
            StatusChip(title: "USD", style: .accent)
            StatusChip(title: "BCRA", style: .category)
            StatusChip(title: "LIVE", style: .live)
            Spacer()
            TerminalButton(title: "Sort", style: .secondary, action: {})
        }
    }
    .padding()
    .background(TerminalScreenBackground())
}
