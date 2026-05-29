import SwiftUI

struct SplashScreen: View {
    var body: some View {
        Color.black
            .overlay {
                Image("splash-bg")
                    .resizable()
                    .scaledToFill()
            }
            .ignoresSafeArea()
    }
}

#Preview {
    SplashScreen()
}
