import SwiftUI

struct MonitorFrame<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(RadarTheme.Colors.surface.opacity(0.001))
            .overlay(
                Rectangle()
                    .stroke(RadarTheme.Colors.border, lineWidth: 1)
            )
    }
}

#Preview("Monitor Frame") {
    MonitorFrame {
        VStack(alignment: .leading, spacing: RadarTheme.Spacing.small) {
            Text("MARKET TABLE")
                .font(RadarTheme.Typography.compactLabel)
                .foregroundStyle(RadarTheme.Colors.textPrimary)
            PanelDivider()
            Text("Dense framed monitor content")
                .font(RadarTheme.Typography.panelSubtitle)
                .foregroundStyle(RadarTheme.Colors.textSecondary)
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
        }
    }
    .padding()
    .background(TerminalScreenBackground())
}
