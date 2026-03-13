import SwiftUI

enum AlertTagSeverity: Equatable {
    case info
    case warning
    case critical
    case success
    case category

    var color: Color {
        switch self {
        case .info:
            return RadarTheme.Colors.info
        case .warning:
            return RadarTheme.Colors.warning
        case .critical:
            return RadarTheme.Colors.negative
        case .success:
            return RadarTheme.Colors.positive
        case .category:
            return RadarTheme.Colors.textSecondary
        }
    }

    var systemImage: String {
        switch self {
        case .info:
            return "info.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .critical:
            return "xmark.octagon.fill"
        case .success:
            return "checkmark.circle.fill"
        case .category:
            return "tag.fill"
        }
    }
}

struct AlertTag: View {
    let title: String
    var severity: AlertTagSeverity = .info
    var showsIcon: Bool? = nil

    private var resolvedShowsIcon: Bool {
        showsIcon ?? (severity != .category)
    }

    var body: some View {
        HStack(spacing: 5) {
            if resolvedShowsIcon {
                Image(systemName: severity.systemImage)
                    .font(.system(size: 10, weight: .semibold))
            }

            Text(title.uppercased())
                .font(RadarTheme.Typography.compactTag)
                .tracking(0.5)
        }
        .foregroundStyle(severity.color)
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(
            Rectangle()
                .fill(severity.color.opacity(0.12))
        )
        .overlay(
            Rectangle()
                .stroke(severity.color.opacity(0.34), lineWidth: 1)
        )
    }
}

#Preview("Alert Tag") {
    HStack {
        AlertTag(title: "live", severity: .info)
        AlertTag(title: "warning", severity: .warning)
        AlertTag(title: "critical", severity: .critical)
        AlertTag(title: "macro", severity: .category)
    }
    .padding()
    .background(TerminalScreenBackground())
}
