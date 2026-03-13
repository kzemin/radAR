import SwiftUI

struct LoadingStateView: View {
    let title: String
    var subtitle = "Actualizando series y paneles con datos públicos del BCRA."

    var body: some View {
        PanelContainer {
            VStack(alignment: .leading, spacing: RadarTheme.Spacing.small) {
                PanelHeader(
                    title: title,
                    subtitle: subtitle,
                    statusTitle: "SYNC",
                    statusStyle: .live
                )

                HStack(spacing: RadarTheme.Spacing.small) {
                    ProgressView()
                        .controlSize(.small)

                    Text("Cargando monitores...")
                        .font(RadarTheme.Typography.panelSubtitle)
                        .foregroundStyle(RadarTheme.Colors.textSecondary)
                }
            }
        }
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    var systemImage = "tray"

    var body: some View {
        PanelContainer {
            VStack(alignment: .leading, spacing: RadarTheme.Spacing.small) {
                PanelHeader(
                    title: title,
                    subtitle: message,
                    statusTitle: "EMPTY",
                    statusStyle: .neutral
                )

                HStack(spacing: RadarTheme.Spacing.small) {
                    Image(systemName: systemImage)
                        .font(RadarTheme.Typography.compactTag)
                        .foregroundStyle(RadarTheme.Colors.textTertiary)

                    Text("No hay datos suficientes para renderizar este bloque.")
                        .font(RadarTheme.Typography.panelSubtitle)
                        .foregroundStyle(RadarTheme.Colors.textSecondary)
                }
            }
        }
    }
}

struct ErrorStateView: View {
    let title: String
    let message: String
    let retryAction: (() -> Void)?

    var body: some View {
        PanelContainer {
            VStack(alignment: .leading, spacing: RadarTheme.Spacing.compact) {
                PanelHeader(
                    title: title,
                    subtitle: message,
                    statusTitle: "ERROR",
                    statusStyle: .alert
                )

                if let retryAction {
                    TerminalButton(
                        title: "Reintentar",
                        style: .secondary,
                        action: retryAction
                    )
                }
            }
        }
    }
}

#Preview("Empty State") {
    EmptyStateView(
        title: "Sin datos disponibles",
        message: "Todavía no hay series cargadas para este panel."
    )
    .padding()
    .background(RadarTheme.Colors.background)
}

#Preview("Error State") {
    ErrorStateView(
        title: "Panel no disponible",
        message: "No pudimos actualizar este bloque con la última respuesta pública.",
        retryAction: {}
    )
    .padding()
    .background(RadarTheme.Colors.background)
}
