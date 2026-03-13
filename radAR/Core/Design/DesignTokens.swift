import SwiftUI

enum RadarTheme {
    enum Colors {
        static let accent = Color(red: 0.34, green: 0.76, blue: 1.00)
        static let accentMuted = Color(red: 0.16, green: 0.27, blue: 0.38)
        static let background = Color(red: 0.02, green: 0.04, blue: 0.06)
        static let backgroundElevated = Color(red: 0.05, green: 0.07, blue: 0.09)
        static let surface = Color(red: 0.07, green: 0.09, blue: 0.12)
        static let surfaceMuted = Color(red: 0.10, green: 0.12, blue: 0.15)
        static let surfaceStrong = Color(red: 0.12, green: 0.15, blue: 0.19)
        static let border = Color(red: 0.19, green: 0.24, blue: 0.29)
        static let separator = Color(red: 0.13, green: 0.16, blue: 0.20)
        static let grid = Color(red: 0.32, green: 0.75, blue: 1.0).opacity(0.06)
        static let textPrimary = Color(red: 0.95, green: 0.97, blue: 0.99)
        static let textSecondary = Color(red: 0.63, green: 0.68, blue: 0.75)
        static let textTertiary = Color(red: 0.46, green: 0.52, blue: 0.59)
        static let positive = Color(red: 0.22, green: 0.84, blue: 0.49)
        static let negative = Color(red: 0.95, green: 0.35, blue: 0.33)
        static let warning = Color(red: 0.96, green: 0.73, blue: 0.22)
        static let info = accent
    }

    enum Spacing {
        static let micro: CGFloat = 2
        static let xSmall: CGFloat = 4
        static let small: CGFloat = 6
        static let compact: CGFloat = 8
        static let row: CGFloat = 8
        static let card: CGFloat = 8
        static let section: CGFloat = 12
        static let screen: CGFloat = 10
    }

    enum Radius {
        static let xSmall: CGFloat = 2
        static let small: CGFloat = 3
        static let control: CGFloat = 3
        static let card: CGFloat = 4
    }

    enum Shadow {
        static let panelOpacity: CGFloat = 0.08
        static let panelRadius: CGFloat = 4
    }

    enum Typography {
        static func sansRegular(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
            .custom("IBMPlexSans-Regular", size: size, relativeTo: style)
        }

        static func sansMedium(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
            .custom("IBMPlexSans-Medium", size: size, relativeTo: style)
        }

        static func sansSemibold(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
            .custom("IBMPlexSans-SemiBold", size: size, relativeTo: style)
        }

        static func sansBold(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
            .custom("IBMPlexSans-Bold", size: size, relativeTo: style)
        }

        static func monoRegular(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
            .custom("IBMPlexMono-Regular", size: size, relativeTo: style)
        }

        static func monoMedium(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
            .custom("IBMPlexMono-Medium", size: size, relativeTo: style)
        }

        static func monoSemibold(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
            .custom("IBMPlexMono-SemiBold", size: size, relativeTo: style)
        }

        static let panelTitle = monoSemibold(11, relativeTo: .caption)
        static let panelSubtitle = monoMedium(10, relativeTo: .caption)
        static let denseSectionTitle = monoSemibold(12, relativeTo: .caption)
        static let denseSectionSubtitle = monoRegular(10, relativeTo: .caption)
        static let rowLabel = sansSemibold(12, relativeTo: .subheadline)
        static let rowSecondary = sansMedium(11, relativeTo: .caption)
        static let body = sansRegular(13, relativeTo: .body)
        static let bodyStrong = sansSemibold(13, relativeTo: .body)
        static let compactLabel = monoSemibold(11, relativeTo: .caption)
        static let compactTag = monoMedium(10, relativeTo: .caption2)
        static let tableValue = monoSemibold(12, relativeTo: .caption)
        static let value = monoSemibold(16, relativeTo: .headline)
        static let largeValue = monoSemibold(22, relativeTo: .title2)
        static let heroValue = monoSemibold(28, relativeTo: .title)
        static let buttonLabel = monoSemibold(11, relativeTo: .caption)
    }
}
