import CoreLocation
import SwiftUI

struct MapaPinCallout: View {
    let event: NewsEvent
    let onDismiss: () -> Void

    @State private var isBodyExpanded = false

    /// Rough threshold: 8 lines × ~45 chars/line at Inter Regular 13pt fits in
    /// the body width. Below it the body already fits, no toggle needed.
    private var canExpand: Bool { event.body.count > 360 }

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            divider
            bodySection
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MapaTheme.Colors.background)
        // Border on three sides only — the card is flush against the screen's
        // left edge, so the left border is intentionally omitted.
        .overlay(alignment: .top) {
            Rectangle().fill(MapaTheme.Colors.info).frame(height: 1)
        }
        .overlay(alignment: .trailing) {
            Rectangle().fill(MapaTheme.Colors.info).frame(width: 1)
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(MapaTheme.Colors.info).frame(height: 1)
        }
        .shadow(color: MapaTheme.Colors.backgroundDeep.opacity(0.5), radius: 12, x: 0, y: 4)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Text(event.province.displayName)
                    .foregroundStyle(MapaTheme.Colors.textSecondary)

                Text("·")
                    .foregroundStyle(MapaTheme.Colors.textTertiary)

                Text(RadarFormatters.relativeShort(event.timestamp))
                    .foregroundStyle(MapaTheme.Colors.textTertiary)
            }
            .textStyle(.cardLocation)
            .lineLimit(1)

            Text(event.headline)
                .textStyle(.cardTitleLarge)
                .foregroundStyle(MapaTheme.Colors.textPrimary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(MapaTheme.Metrics.cardPadding)
        .padding(.trailing, 110)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .trailing) {
            EventThumbnail(event: event, width: 104)
                .allowsHitTesting(false)
        }
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 10) {
                EventCardTags(event: event)

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(MapaTheme.Colors.textPrimary)
                        .shadow(color: MapaTheme.Colors.backgroundDeep.opacity(0.6), radius: 2, x: 0, y: 1)
                        .padding(4)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cerrar")
            }
            .padding(.top, 8)
            .padding(.trailing, 8)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(MapaTheme.Colors.border)
            .frame(height: 1)
    }

    private var bodySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if isBodyExpanded {
                ScrollView(.vertical, showsIndicators: true) {
                    bodyParagraph()
                }
                .frame(maxHeight: MapaTheme.Metrics.calloutBodyMaxHeight)
            } else {
                bodyParagraph(lineLimit: 8)
            }

            if canExpand {
                expandButton
            }
        }
        .padding(MapaTheme.Metrics.cardPadding)
    }

    private func bodyParagraph(lineLimit: Int? = nil) -> some View {
        Text(event.body)
            .textStyle(.cardBody)
            .foregroundStyle(MapaTheme.Colors.textSecondary)
            .multilineTextAlignment(.leading)
            .lineLimit(lineLimit)
            .truncationMode(.tail)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var expandButton: some View {
        Button {
            isBodyExpanded.toggle()
        } label: {
            HStack(spacing: 4) {
                Text((isBodyExpanded ? "menos" : "más").uppercased())
                    .textStyle(.cardTag)
                    .foregroundStyle(MapaTheme.Colors.info)

                Image(systemName: isBodyExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(MapaTheme.Colors.info)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
