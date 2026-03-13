import SwiftUI

struct RadarCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        PanelContainer {
            content
        }
    }
}
