import SwiftUI

struct ColoredBackground<Content: View>: View {
    let content: Content
    let backgroundColor: Color

    init(@ViewBuilder _ content: () -> Content, color: ColorResource = .smoke) {
        self.content = content()
        self.backgroundColor = Color(color)
    }

    init(@ViewBuilder _ content: () -> Content, color: Color) {
        self.content = content()
        self.backgroundColor = color
    }

    var body: some View {
        ZStack {
            backgroundColor
                .edgesIgnoringSafeArea(.all)
            content
        }
    }
}
