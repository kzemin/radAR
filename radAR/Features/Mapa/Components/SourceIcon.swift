import SwiftUI
import UIKit

/// Small leading-edge logo for a news source. Looks up an asset named
/// `source-<sourceID>` (e.g. `source-clarin`, `source-lanacion`). Falls back to
/// a muted newspaper SF symbol when the asset hasn't been added yet, so the
/// layout shape is always the same.
///
/// Drop logos into `Assets.xcassets/source-clarin.imageset`, etc. — squarish
/// dark-mode-friendly PNGs work best.
struct SourceIcon: View {
    let sourceID: String?
    var size: CGFloat = 12

    var body: some View {
        Group {
            if let id = sourceID, UIImage(named: "source-\(id)") != nil {
                Image("source-\(id)")
                    .resizable()
                    .scaledToFit()
            } else {
                // Emoji reads better than an SF symbol against the dark map
                // backdrop, and survives the "no logo asset yet" state cleanly.
                Text("📰")
                    .font(.system(size: size))
            }
        }
        .frame(width: size, height: size)
        // Uniform circular frame so outlet marks read as a coherent set
        // regardless of their original aspect / palette.
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.black, lineWidth: 1))
    }
}
