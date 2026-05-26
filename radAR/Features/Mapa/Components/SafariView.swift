import SafariServices
import SwiftUI

/// In-app browser for source links. Wraps `SFSafariViewController` so taps on a
/// headline open the article without bouncing the user out to Safari.
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        let controller = SFSafariViewController(url: url, configuration: config)
        controller.preferredBarTintColor = UIColor(MapaTheme.Colors.background)
        controller.preferredControlTintColor = UIColor(MapaTheme.Colors.info)
        controller.dismissButtonStyle = .close
        return controller
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
