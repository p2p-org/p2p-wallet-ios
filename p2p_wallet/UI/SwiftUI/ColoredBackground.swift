import KeyAppUI
import SwiftUI

struct ColoredBackground<Content: View>: View {
    let content: Content
    let backgroundColor: Color

    init(@ViewBuilder _ content: () -> Content, color: UIColor = Asset.Colors.smoke.color) {
        self.content = content()
        backgroundColor = Color(color)
    }

    init(@ViewBuilder _ content: () -> Content, color: Color) {
        self.content = content()
        backgroundColor = color
    }

    var body: some View {
        ZStack {
            backgroundColor
                .edgesIgnoringSafeArea(.all)
            content
        }
    }
}
