import KeyAppUI
import SwiftUI

struct OnboardingScreen: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(Asset.Colors.lime.color))
            .edgesIgnoringSafeArea(.all)
            .frame(maxHeight: .infinity)
    }
}
