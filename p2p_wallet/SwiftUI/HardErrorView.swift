import SwiftUI
import KeyAppUI

/// An error view with a woman image :)
struct HardErrorView<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder public var content: () -> Content

    var body: some View {
        VStack {
            Spacer()
            OnboardingContentView(
                data: .init(
                    image: .womanHardError,
                    title: title,
                    subtitle: subtitle
                )
            )
                .padding(.bottom, 48)

            BottomActionContainer {
                content()
            }
        }
        .hardErrorScreen()
    }
}

private extension View {
    func hardErrorScreen() -> some View {
        background(Color(Asset.Colors.smoke.color))
            .edgesIgnoringSafeArea(.all)
            .frame(maxHeight: .infinity)
    }
}

struct HardErrorView_Previews: PreviewProvider {
    static var previews: some View {
        HardErrorView(
            title: "Title",
            subtitle: "Subtitle") {
                VStack {
                    Text("1")
                    Text("2")
                    Text("3")
                }
            }
    }
}
