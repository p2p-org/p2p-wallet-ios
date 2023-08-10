import SwiftUI

struct OnboardingScreen: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(.lime))
            .edgesIgnoringSafeArea(.all)
            .frame(maxHeight: .infinity)
    }
}
