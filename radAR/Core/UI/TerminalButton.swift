import SwiftUI

enum TerminalButtonStyle {
    case primary
    case secondary
    case ghost
}

struct TerminalButton: View {
    let title: String
    var style: TerminalButtonStyle = .primary
    var action: () -> Void

    private var foregroundColor: Color {
        switch style {
        case .primary:
            return RadarTheme.Colors.surface
        case .secondary:
            return RadarTheme.Colors.accent
        case .ghost:
            return RadarTheme.Colors.textPrimary
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return RadarTheme.Colors.accent
        case .secondary:
            return RadarTheme.Colors.surface
        case .ghost:
            return .clear
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary:
            return RadarTheme.Colors.accent
        case .secondary:
            return RadarTheme.Colors.accent
        case .ghost:
            return RadarTheme.Colors.border
        }
    }

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(RadarTheme.Typography.buttonLabel)
                .tracking(0.7)
                .foregroundStyle(foregroundColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    Rectangle()
                        .fill(backgroundColor)
                )
                .overlay(
                    Rectangle()
                        .stroke(borderColor, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview("Terminal Button") {
    HStack(spacing: 12) {
        TerminalButton(title: "Open", style: .primary, action: {})
        TerminalButton(title: "Filter", style: .secondary, action: {})
        TerminalButton(title: "Clear", style: .ghost, action: {})
    }
    .padding()
    .background(TerminalScreenBackground())
}
