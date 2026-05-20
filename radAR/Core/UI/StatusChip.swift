import SwiftUI

enum StatusChipStyle {
    case neutral
    case accent
    case positive
    case negative
    case warning
    case live
    case alert
    case category
    case info

    var foregroundColor: Color {
        switch self {
        case .neutral:
            return RadarTheme.Colors.textPrimary
        case .accent:
            return RadarTheme.Colors.accent
        case .positive:
            return RadarTheme.Colors.positive
        case .negative:
            return RadarTheme.Colors.negative
        case .warning:
            return RadarTheme.Colors.warning
        case .live:
            return RadarTheme.Colors.accent
        case .alert:
            return RadarTheme.Colors.warning
        case .category:
            return RadarTheme.Colors.textPrimary
        case .info:
            return RadarTheme.Colors.info
        }
    }

    var backgroundColor: Color {
        RadarTheme.Colors.surface
    }

    var borderColor: Color {
        foregroundColor
    }
}

struct StatusChip: View {
    let title: String
    var style: StatusChipStyle = .neutral
    var isEmphasized = false

    var body: some View {
        Text(title.uppercased())
            .font(RadarTheme.Typography.compactTag)
            .tracking(0.6)
            .foregroundStyle(style.foregroundColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                Rectangle()
                    .fill(isEmphasized ? style.foregroundColor.opacity(0.18) : style.backgroundColor)
            )
            .overlay(
                Rectangle()
                    .stroke(style.borderColor, lineWidth: 1)
            )
    }
}

#Preview("Status Chip") {
    HStack {
        StatusChip(title: "Live", style: .live, isEmphasized: true)
        StatusChip(title: "Alert", style: .alert)
        StatusChip(title: "BCRA", style: .category)
        StatusChip(title: "USD", style: .accent)
        StatusChip(title: "Up", style: .positive)
        StatusChip(title: "Down", style: .negative)
    }
    .padding()
    .background(TerminalScreenBackground())
}
