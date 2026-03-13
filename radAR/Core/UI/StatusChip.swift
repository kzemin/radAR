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
            return RadarTheme.Colors.textSecondary
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
            return Color(red: 0.78, green: 0.84, blue: 0.92)
        case .info:
            return RadarTheme.Colors.info
        }
    }

    var backgroundColor: Color {
        foregroundColor.opacity(0.12)
    }

    var borderColor: Color {
        foregroundColor.opacity(0.35)
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
