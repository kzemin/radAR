import SwiftUI

extension RadarTheme {
    struct TextStyle {
        let font: Font
        let lineSpacing: CGFloat
        let tracking: CGFloat

        init(font: Font, lineSpacing: CGFloat = 0, tracking: CGFloat = 0) {
            self.font = font
            self.lineSpacing = lineSpacing
            self.tracking = tracking
        }
    }
}

// MARK: - News cards

extension RadarTheme.TextStyle {
    /// Title of a news card inside the drawer.
    static let cardTitle = RadarTheme.TextStyle(
        font: RadarTheme.Typography.sansSemibold(15, relativeTo: .headline)
    )
    /// Title of the floating pin callout. Slightly larger, up to three lines.
    static let cardTitleLarge = RadarTheme.TextStyle(
        font: RadarTheme.Typography.sansSemibold(16, relativeTo: .headline)
    )
    /// "Noticias" section header at the top of the bottom drawer.
    static let drawerTitle = RadarTheme.TextStyle(
        font: RadarTheme.Typography.sansSemibold(15, relativeTo: .headline)
    )
    /// Muted descriptor under the drawer title ("Últimas 24 horas").
    static let drawerSubtitle = RadarTheme.TextStyle(
        font: RadarTheme.Typography.sansMedium(11, relativeTo: .caption)
    )
    /// Brand sign-off at the end of the drawer list ("radAR · 2026").
    static let drawerFooter = RadarTheme.TextStyle(
        font: RadarTheme.Typography.monoMedium(10, relativeTo: .caption2),
        tracking: 2
    )
    /// Location subtitle ("Ciudad de Buenos Aires") shown above the title.
    static let cardLocation = RadarTheme.TextStyle(
        font: RadarTheme.Typography.sansMedium(10, relativeTo: .caption2)
    )
    /// LIVE / POL / ECO tag text rendered directly on the thumbnail.
    static let cardTag = RadarTheme.TextStyle(
        font: RadarTheme.Typography.monoSemibold(10, relativeTo: .caption2),
        tracking: 0.7
    )
    /// Body text shown under a divider in the floating callout — the news's
    /// description / lead paragraph.
    static let cardBody = RadarTheme.TextStyle(
        font: RadarTheme.Typography.sansRegular(13, relativeTo: .body),
        lineSpacing: 2
    )
}

// MARK: - Ticker

extension RadarTheme.TextStyle {
    /// Quote/stat label in the top ticker ("Dólar oficial", "Riesgo país"). Sans.
    static let tickerLabel = RadarTheme.TextStyle(
        font: RadarTheme.Typography.sansMedium(13, relativeTo: .footnote)
    )
    /// Numeric value in the top ticker ($1.245, +0,3%). Tabular mono.
    static let tickerValue = RadarTheme.TextStyle(
        font: RadarTheme.Typography.monoSemibold(13, relativeTo: .footnote)
    )
    /// Body of the URGENTE banner. Sans, semibold, sits on the orange chip.
    static let tickerUrgent = RadarTheme.TextStyle(
        font: RadarTheme.Typography.sansSemibold(13, relativeTo: .footnote)
    )
    /// "URGENTE" label that sits on the white badge next to the urgent body.
    static let tickerUrgentLabel = RadarTheme.TextStyle(
        font: RadarTheme.Typography.sansBold(12, relativeTo: .footnote),
        tracking: 0.6
    )
}

// MARK: - Headers + chrome

extension RadarTheme.TextStyle {
    /// "radAR" brand mark in the floating header.
    static let appTitle = RadarTheme.TextStyle(
        font: RadarTheme.Typography.monoSemibold(22, relativeTo: .title2)
    )
    /// Provincia / "Argentina" subtitle under the brand mark.
    static let appSubtitle = RadarTheme.TextStyle(
        font: RadarTheme.Typography.monoSemibold(11, relativeTo: .caption),
        tracking: 0.9
    )
}

// MARK: - View modifier

extension View {
    func textStyle(_ style: RadarTheme.TextStyle) -> some View {
        modifier(TextStyleModifier(style: style))
    }
}

private struct TextStyleModifier: ViewModifier {
    let style: RadarTheme.TextStyle

    func body(content: Content) -> some View {
        content
            .font(style.font)
            .lineSpacing(style.lineSpacing)
            .tracking(style.tracking)
    }
}
